using Mono.Cecil;
using Mono.Cecil.Cil;

// ── Argument parsing ──────────────────────────────────────────────────────────
if (args.Length == 0 || args[0] is "-h" or "--help")
{
    PrintUsage();
    return args.Length == 0 ? 1 : 0;
}

string inputPath    = args[0];
string outputFile   = "business_rules.csv";
string? baseFilter  = null;
bool recursive      = true;
bool verbose        = false;

for (int i = 1; i < args.Length; i++)
{
    switch (args[i])
    {
        case "-o" or "--output" when i + 1 < args.Length:
            outputFile = args[++i];
            break;
        case "-b" or "--base" when i + 1 < args.Length:
            baseFilter = args[++i];
            break;
        case "--no-recursive":
            recursive = false;
            break;
        case "-v" or "--verbose":
            verbose = true;
            break;
        default:
            Console.Error.WriteLine($"Unknown option: {args[i]} (use --help)");
            return 1;
    }
}

// ── Resolve DLL files ─────────────────────────────────────────────────────────
string[] dllFiles;

if (File.Exists(inputPath) && inputPath.EndsWith(".dll", StringComparison.OrdinalIgnoreCase))
{
    dllFiles = [inputPath];
}
else if (Directory.Exists(inputPath))
{
    dllFiles = Directory.GetFiles(
        inputPath, "*.dll",
        recursive ? SearchOption.AllDirectories : SearchOption.TopDirectoryOnly);
}
else
{
    Console.Error.WriteLine($"Error: path not found — {inputPath}");
    return 1;
}

Console.WriteLine($"Scanning {dllFiles.Length} DLL(s) in: {Path.GetFullPath(inputPath)}");
if (baseFilter != null)
    Console.WriteLine($"Base class filter: '{baseFilter}'");

// ── Scan assemblies ───────────────────────────────────────────────────────────
var results  = new List<RuleInfo>();
var errorLog = new List<string>();
int scanned  = 0;

foreach (string dllPath in dllFiles.OrderBy(f => f))
{
    try
    {
        var resolver = new DefaultAssemblyResolver();
        resolver.AddSearchDirectory(Path.GetDirectoryName(Path.GetFullPath(dllPath))!);

        var rp = new ReaderParameters
        {
            AssemblyResolver          = resolver,
            ReadingMode               = ReadingMode.Immediate,
            ThrowIfSymbolsAreNotMatching = false,
            InMemory                  = true,
        };

        using var asm = AssemblyDefinition.ReadAssembly(dllPath, rp);
        scanned++;

        foreach (TypeDefinition type in FlattenTypes(asm.MainModule.Types))
        {
            if (type.IsAbstract || type.IsInterface || !type.IsClass) continue;

            // Optional: restrict to classes that extend a named base
            if (baseFilter != null)
            {
                string baseName = type.BaseType?.Name ?? string.Empty;
                if (!baseName.Contains(baseFilter, StringComparison.OrdinalIgnoreCase))
                    continue;
            }

            MethodDefinition? getName = FindNoArgMethod(type, "GetName");
            MethodDefinition? getDesc = FindNoArgMethod(type, "GetDescription");

            if (getName == null && getDesc == null) continue;

            string name = ExtractStringReturn(getName);
            string desc = ExtractStringReturn(getDesc);

            if (verbose)
            {
                Console.WriteLine($"  {type.FullName}");
                Console.WriteLine($"    Name        : {name}");
                Console.WriteLine($"    Description : {Truncate(desc, 80)}");
            }

            results.Add(new RuleInfo(
                AssemblyFile : Path.GetFileName(dllPath),
                FilePath     : Path.GetFullPath(dllPath),
                ClassName    : type.FullName,
                Name         : name,
                Description  : desc
            ));
        }
    }
    catch (BadImageFormatException)
    {
        // Native DLL or corrupt — silently skip unless verbose
        if (verbose)
            Console.WriteLine($"  [skipped] Not a .NET assembly: {Path.GetFileName(dllPath)}");
    }
    catch (Exception ex)
    {
        errorLog.Add($"{Path.GetFileName(dllPath)}: {ex.Message}");
    }
}

// ── Write CSV ─────────────────────────────────────────────────────────────────
string outPath = Path.GetFullPath(outputFile);
Directory.CreateDirectory(Path.GetDirectoryName(outPath)!);

using (var w = new StreamWriter(outPath, append: false, System.Text.Encoding.UTF8))
{
    w.WriteLine("AssemblyFile,FilePath,ClassName,P21-Name,Description");
    foreach (RuleInfo r in results.OrderBy(r => r.AssemblyFile).ThenBy(r => r.ClassName))
        w.WriteLine($"{Csv(r.AssemblyFile)},{Csv(r.FilePath)},{Csv(r.ClassName)},{Csv(r.Name)},{CsvQuoted(r.Description)}");
}

// ── Summary ───────────────────────────────────────────────────────────────────
Console.WriteLine();
Console.WriteLine($"DLLs scanned : {scanned} / {dllFiles.Length}");
Console.WriteLine($"Rules found  : {results.Count}");
Console.WriteLine($"Output       : {outPath}");

if (errorLog.Count > 0)
{
    Console.ForegroundColor = ConsoleColor.Yellow;
    Console.WriteLine($"\nWarnings — {errorLog.Count} DLL(s) could not be fully read:");
    foreach (string e in errorLog) Console.WriteLine($"  {e}");
    Console.ResetColor();
}

return 0;

// ── Helpers ───────────────────────────────────────────────────────────────────

// Recursively yield all types including nested types.
static IEnumerable<TypeDefinition> FlattenTypes(IEnumerable<TypeDefinition> types)
{
    foreach (TypeDefinition t in types)
    {
        yield return t;
        if (t.HasNestedTypes)
            foreach (TypeDefinition nested in FlattenTypes(t.NestedTypes))
                yield return nested;
    }
}

// Find an overriding (non-abstract, non-static, body-present) parameterless method.
static MethodDefinition? FindNoArgMethod(TypeDefinition type, string name)
    => type.Methods.FirstOrDefault(m =>
        m.Name == name &&
        m.Parameters.Count == 0 &&
        !m.IsStatic &&
        !m.IsAbstract &&
        m.HasBody);

// Walk IL and return the last string literal loaded before a ret instruction.
// Handles the common P21 pattern: ldstr "value" / ret
// Returns "(dynamic)" when the return value is computed at runtime.
static string ExtractStringReturn(MethodDefinition? method)
{
    if (method == null)       return string.Empty;
    if (!method.HasBody)      return "(no body)";

    string? lastLiteral = null;

    foreach (Instruction inst in method.Body.Instructions)
    {
        if (inst.OpCode == OpCodes.Ldstr)
            lastLiteral = inst.Operand as string;
        else if (inst.OpCode == OpCodes.Ret && lastLiteral != null)
            return lastLiteral;
    }

    return lastLiteral ?? "(dynamic)";
}

static string Csv(string? value)
{
    if (string.IsNullOrEmpty(value)) return string.Empty;
    if (value.Contains(',') || value.Contains('"') || value.Contains('\n') || value.Contains('\r'))
        return $"\"{value.Replace("\"", "\"\"")}\"";
    return value;
}

// Always wraps in quotes — used for free-text fields like Description
// that may contain commas, semicolons, or other delimiter characters.
static string CsvQuoted(string? value)
    => $"\"{(value ?? string.Empty).Replace("\"", "\"\"")}\"";

static string Truncate(string s, int max)
    => s.Length <= max ? s : string.Concat(s.AsSpan(0, max), "…");

static void PrintUsage()
{
    Console.WriteLine("BusinessRuleExporter  —  Extract P21 Business Rule metadata from .dll files");
    Console.WriteLine();
    Console.WriteLine("Usage:");
    Console.WriteLine("  BusinessRuleExporter <path> [options]");
    Console.WriteLine();
    Console.WriteLine("Arguments:");
    Console.WriteLine("  <path>               Path to a .dll file  OR  a directory to scan");
    Console.WriteLine();
    Console.WriteLine("Options:");
    Console.WriteLine("  -o, --output <file>  Output CSV path          (default: business_rules.csv)");
    Console.WriteLine("  -b, --base   <name>  Only include classes whose direct base class name");
    Console.WriteLine("                         contains <name>  (e.g. -b Rule  or  -b BusinessRule)");
    Console.WriteLine("      --no-recursive   Do not descend into subdirectories");
    Console.WriteLine("  -v, --verbose        Print each match to the console");
    Console.WriteLine("  -h, --help           Show this message");
    Console.WriteLine();
    Console.WriteLine("CSV columns:");
    Console.WriteLine("  AssemblyFile   — DLL filename");
    Console.WriteLine("  ClassName      — Fully qualified type name");
    Console.WriteLine("  Name           — Return value of GetName()");
    Console.WriteLine("  Description    — Return value of GetDescription()");
    Console.WriteLine();
    Console.WriteLine("Examples:");
    Console.WriteLine("  BusinessRuleExporter C:\\P21\\Custom\\Rules -o rules.csv");
    Console.WriteLine("  BusinessRuleExporter C:\\P21\\Custom\\Rules -b Rule -v");
    Console.WriteLine("  BusinessRuleExporter MyRule.dll");
}

record RuleInfo(string AssemblyFile, string FilePath, string ClassName, string Name, string Description);
