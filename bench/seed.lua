--- Generate benchmark test projects
-- Run: nvim --headless -c "luafile bench/seed.lua" -c "qa!"
-- Generates projects into bench/projects/ (persistent, not tracked)

local bench_dir = vim.fn.getcwd() .. "/bench"
local base = bench_dir .. "/projects"

local sizes = {
    small = { count = 10, lines_per = 5, depth = 1 },
    medium = { count = 100, lines_per = 20, depth = 2 },
    large = { count = 1000, lines_per = 50, depth = 3 },
}

local huge_count = 10000

function gen_project(size, config)
    local dir = base .. "/" .. size
    os.execute("rm -rf " .. dir)
    os.execute("mkdir -p " .. dir)
    os.execute(string.format("mkdir -p %s/src", dir))

    local tsconfig = io.open(dir .. "/tsconfig.json", "w")
    tsconfig:write([[{
  "compilerOptions": {
    "target": "ESNext", "module": "ESNext", "moduleResolution": "bundler",
    "strict": true, "esModuleInterop": true, "outDir": "./dist", "rootDir": "./src"
  },
  "include": ["src/**/*.ts"]
}
]])
    tsconfig:close()

    for i = 1, config.count do
        local fn = string.format("%s/src/file_%04d.ts", dir, i)
        local f = io.open(fn, "w")
        local imports = {}
        for j = math.max(1, i - config.depth), i - 1 do
            table.insert(imports, string.format("import { Data_%04d } from './file_%04d';", j, j))
        end
        f:write("// File " .. i .. " of " .. config.count .. " (" .. size .. " project)\n\n")
        for _, imp in ipairs(imports) do
            f:write(imp .. "\n")
        end
        f:write("\n")
        f:write(string.format(
            [[
export interface Data_%04d { id: number; name: string; value: number; items: string[]; active: boolean; metadata: Record<string, unknown>; }
]],
            i
        ))
        for j = 1, math.max(1, math.floor(config.lines_per / 4)) do
            f:write(string.format(
                [[
export function handler_%04d_%d(data: Data_%04d): string { return `Processing ${data.name} with value ${data.value}`; }
]],
                i,
                j,
                i
            ))
        end
        f:close()
    end

    local index = io.open(dir .. "/src/index.ts", "w")
    index:write("// Main entry point\n\n")
    for i = 1, config.count do
        index:write(string.format("import { Data_%04d, handler_%04d_1 } from './file_%04d';\n", i, i, i))
    end
    index:write("\nexport const allData: unknown[] = [\n")
    for i = 1, config.count do
        index:write(string.format("  {} as Data_%04d,\n", i))
    end
    index:write("];\n")
    index:close()
    return dir
end

function gen_huge()
    local dir = base .. "/huge"
    os.execute("rm -rf " .. dir)
    os.execute("mkdir -p " .. dir)
    os.execute(string.format("mkdir -p %s/src", dir))
    local tscfg = io.open(dir .. "/tsconfig.json", "w")
    tscfg:write(
        [[{"compilerOptions":{"target":"ESNext","module":"ESNext","strict":true,"outDir":"./dist","rootDir":"./src"},"include":["src/**/*.ts"]}]]
    )
    tscfg:close()
    for batch = 1, 100 do
        for i = (batch - 1) * 100 + 1, math.min(batch * 100, huge_count) do
            local f = io.open(string.format("%s/src/file_%05d.ts", dir, i), "w")
            f:write(
                string.format(
                    'export interface Data_%05d { id: number; name: string; value: number; active: boolean }\nexport function get_%05d(): Data_%05d { return { id: %d, name: "item_%d", value: %d, active: true }; }\n',
                    i,
                    i,
                    i,
                    i,
                    i,
                    i % 100
                )
            )
            f:close()
        end
        io.write(string.format("\rHuge: %d/%d", math.min(batch * 100, huge_count), huge_count))
        io.flush()
    end
    io.write("\n")
    local idx = io.open(dir .. "/src/index.ts", "w")
    idx:write("export const all: unknown[] = [\n")
    for i = 1, huge_count do
        idx:write(string.format("  {} as Data_%05d,\n", i))
    end
    idx:write("];\n")
    idx:close()
    return dir
end

function gen_monorepo()
    local dir = base .. "/monorepo"
    os.execute("rm -rf " .. dir)
    os.execute("mkdir -p " .. dir)
    local packages = { "core", "utils", "types", "api", "web", "mobile", "admin", "shared", "hooks", "config" }
    for _, pkg in ipairs(packages) do
        os.execute(string.format("mkdir -p %s/packages/%s/src", dir, pkg))
        local tsf = io.open(string.format("%s/packages/%s/tsconfig.json", dir, pkg), "w")
        tsf:write(
            string.format(
                '{"compilerOptions":{"target":"ESNext","module":"ESNext","strict":true,"outDir":"./dist"},"include":["src/**/*.ts"]}'
            )
        )
        tsf:close()
        local deps = {}
        for _, other in ipairs(packages) do
            if other ~= pkg then
                table.insert(deps, string.format('"@project/%s": "workspace:*"', other))
            end
        end
        local pjf = io.open(string.format("%s/packages/%s/package.json", dir, pkg), "w")
        pjf:write(string.format('{"name":"@project/%s","dependencies":{%s}}', pkg, table.concat(deps, ",")))
        pjf:close()
        for i = 1, 50 do
            local f = io.open(string.format("%s/packages/%s/src/module_%03d.ts", dir, pkg, i), "w")
            f:write(
                string.format(
                    'export interface Module_%s_%d { id: string; data: unknown; }\nexport function create_%s_%d(): Module_%s_%d { return { id: "%s_%d", data: null }; }\n',
                    pkg,
                    i,
                    pkg,
                    i,
                    pkg,
                    i,
                    pkg,
                    i
                )
            )
            f:close()
        end
    end
    local rtc = io.open(dir .. "/tsconfig.json", "w")
    rtc:write('{"compilerOptions":{"target":"ESNext","module":"ESNext","strict":true},"references":[\n')
    for _, pkg in ipairs(packages) do
        rtc:write(string.format('  {"path":"./packages/%s"},\n', pkg))
    end
    rtc:write("]}\n")
    rtc:close()
    return dir
end

function gen_worstcase()
    local dir = base .. "/worstcase"
    os.execute("rm -rf " .. dir)
    os.execute("mkdir -p " .. dir .. "/src/types")
    os.execute("mkdir -p " .. dir .. "/src/generated")

    -- complex-generics.ts
    local f = io.open(dir .. "/src/types/complex-generics.ts", "w")
    f:write([[
export type DeepPartial<T> = T extends object ? { [P in keyof T]?: DeepPartial<T[P]> } : T;
export type DeepRequired<T> = T extends object ? { [P in keyof T]-?: DeepRequired<T[P]> } : T;
export type DeepReadonly<T> = T extends object ? { readonly [P in keyof T]: DeepReadonly<T[P]> } : T;
export type DeepNonNullable<T> = T extends object ? { [P in keyof T]: DeepNonNullable<NonNullable<T[P]>> } : NonNullable<T>;
export type Conditional<T, U, V, W> = T extends U ? V : W;
export type UnionToIntersection<U> = (U extends unknown ? (k: U) => void : never) extends (k: infer I) => void ? I : never;
export type FunctionPropertyNames<T> = { [K in keyof T]: T[K] extends (...args: unknown[]) => unknown ? K : never }[keyof T];
export type PickByValue<T, V> = { [P in keyof T as T[P] extends V ? P : never]: T[P] };
export type Mutable<T> = { -readonly [P in keyof T]: T[P] };
export type Nullable<T> = { [P in keyof T]: T[P] | null };
export type Brand<T, B> = T & { __brand: B };
export type DeepPick<T, Path extends string> = Path extends `${infer K}.${infer R}` ? K extends keyof T ? DeepPick<T[K], R> : never : Path extends keyof T ? T[Path] : never;
export type Await<T> = T extends Promise<infer U> ? U : T;
export type DeepMerge<A, B> = { [K in keyof A | keyof B]: K extends keyof A ? K extends keyof B ? A[K] extends object ? B[K] extends object ? DeepMerge<A[K], B[K]> : B[K] : B[K] : A[K] : K extends keyof B ? B[K] : never; };
]])
    f:close()

    -- massive-file.ts (4550 lines)
    local mf = io.open(dir .. "/src/generated/massive-file.ts", "w")
    for i = 1, 50 do
        mf:write(string.format(
            [[
export interface MegaInterface_%d { id: number; name: string; description: string; status: 'active'|'inactive'|'pending'|'archived'; priority: 1|2|3|4|5; tags: string[]; metadata: Record<string, unknown>; nested: { field1: string; field2: number; field3: boolean; field4: string[]; field5: Record<string, number>; deep: { value: string; items: { id: number; label: string }[]; transform: <T>(val: T) => Promise<T>; } }; createdAt: Date; updatedAt: Date; deletedAt: Date | null; }
export class MegaClass_%d { private items: Map<string, MegaInterface_%d>; private cache: WeakMap<object, string>; constructor(private readonly config: { ttl: number; maxSize: number }) {} async findById(id: number): Promise<MegaInterface_%d | null> { const key = "item_"+id; const cached = this.items.get(key); if (cached) return cached; const result = await this.fetchFromServer(id); if (result) { this.items.set(key, result); this.evictStale(); } return result; } private async fetchFromServer(id: number): Promise<MegaInterface_%d | null> { const response = await fetch('/api/items/'+id); if (!response.ok) return null; return response.json() as Promise<MegaInterface_%d>; } private evictStale(): void { if (this.items.size > this.config.maxSize) { const first = this.items.keys().next().value; if (first) this.items.delete(first); } } *[Symbol.iterator](): IterableIterator<[string, MegaInterface_%d]> { return this.items.entries(); } }
]],
            i,
            i,
            i,
            i,
            i,
            i,
            i
        ))
    end
    for i = 1, 100 do
        mf:write(
            string.format(
                'function deeplyGenericChain_%d<T,U,V,W,X>(a:T,b:U,c:V,d:W,e:X):Promise<[T,U,V,W,X]>{return Promise.resolve([a,b,c,d,e]);}\nconst result_%d=await deeplyGenericChain_%d(42 as const,"hello" as const,true as const,{key:"value"} as const,[1,2,3] as const);\n',
                i,
                i,
                i
            )
        )
    end
    mf:close()

    -- error-bomb.ts (50 deliberate errors)
    local eb = io.open(dir .. "/src/generated/error-bomb.ts", "w")
    eb:write(
        "import { MegaInterface_1 } from './massive-file';\nimport { DeepPartial, DeepRequired } from '../types/complex-generics';\n"
    )
    local errs = {
        'const a: number = "not a number";',
        "const b: string = 42;",
        'const c: boolean = "true";',
        "const d: string[] = 123;",
        'const e: Record<string, number> = { key: "value" };',
        'const f: MegaInterface_1 = { id: "string" };',
        'const g: DeepPartial<MegaInterface_1> = "completely wrong";',
        "const h: DeepRequired<MegaInterface_1> = {};",
        "function fn1(x: number): string { return x * 2; }",
        "function fn2(x: string): number[] { return x; }",
        "class WrongClass { method(): string { return 42; } }",
        'const arr: number[] = ["a", "b", "c"];',
        "const set: Set<string> = new Set([1, 2, 3]);",
        'const map: Map<string, number> = new Map([[1, "x"]]);',
        "const promise: Promise<string> = Promise.resolve(42);",
        'const tuple: [number, string] = ["hello", 42];',
    }
    for i = 1, 50 do
        eb:write(string.format("// Error %d\n%s\n", i, errs[(i - 1) % #errs + 1]))
    end
    eb:close()

    -- import chain A..J
    for i = 1, 10 do
        local letter = string.char(64 + i)
        local next_letter = string.char(65 + i)
        local cf = io.open(string.format("%s/src/generated/chain_%s.ts", dir, letter:lower()), "w")
        if i == 1 then
            cf:write(
                string.format(
                    "import { MegaInterface_1 } from './massive-file';\nexport interface Chain%s extends MegaInterface_1 { chainId: '%s'; chainData: ChainB; }\n",
                    letter,
                    letter
                )
            )
        elseif i < 10 then
            cf:write(
                string.format(
                    "import { Chain%s } from './chain_%s';\nexport interface Chain%s extends Chain%s { chainId: '%s'; chainData: Chain%s; }\n",
                    string.char(64 + i - 1),
                    string.char(96 + i - 1),
                    letter,
                    string.char(64 + i - 1),
                    letter,
                    next_letter
                )
            )
        else
            cf:write(
                string.format(
                    "import { Chain%s } from './chain_%s';\nexport interface Chain%s extends Chain%s { chainId: '%s'; chainData: string; }\n",
                    string.char(64 + i - 1),
                    string.char(96 + i - 1),
                    letter,
                    string.char(64 + i - 1),
                    letter
                )
            )
        end
        cf:close()
    end

    -- circular imports
    local ca = io.open(dir .. "/src/generated/circular_a.ts", "w")
    ca:write(
        "import { CircularB } from './circular_b';\nexport interface CircularA { b: CircularB; name: string; }\nexport function createA(): CircularA { return { b: { a: null, value: 42 }, name: \"circular\" }; }\n"
    )
    ca:close()
    local cb = io.open(dir .. "/src/generated/circular_b.ts", "w")
    cb:write(
        "import { CircularA } from './circular_a';\nexport interface CircularB { a: CircularA | null; value: number; }\nexport function createB(): CircularB { return { a: null, value: 42 }; }\n"
    )
    cb:close()

    -- index.ts
    local idx = io.open(dir .. "/src/generated/index.ts", "w")
    idx:write("import { DeepPartial, DeepRequired, Brand, Conditional } from '../types/complex-generics';\n")
    idx:write("import { MegaInterface_1, MegaClass_1 } from './massive-file';\n")
    idx:write("import { ChainA } from './chain_a';\n")
    idx:write("const mega = new MegaClass_1({ ttl: 5000, maxSize: 1000 });\n")
    idx:write(
        "async function demo(): Promise<void> { const item = await mega.findById(1); if (item) { const p: DeepPartial<typeof item> = { name: 'partial' }; console.log(p); } }\n"
    )
    idx:write(
        "type BrandedId = Brand<number, 'UserId'>;\nconst userId: BrandedId = 42 as BrandedId;\ntype TestGeneric = Conditional<string, string, number, boolean>;\n"
    )
    idx:write("demo().catch(console.error);\n")
    idx:close()

    -- tsconfig
    local tsf = io.open(dir .. "/tsconfig.json", "w")
    tsf:write(
        '{"compilerOptions":{"target":"ESNext","module":"ESNext","strict":true,"outDir":"./dist","rootDir":"./src"},"include":["src/**/*.ts"]}'
    )
    tsf:close()

    return dir
end

print("Seeding benchmark projects in " .. base .. " ...\n")

gen_project("small", sizes.small)
print("  small (10 files): done")
gen_project("medium", sizes.medium)
print("  medium (100 files): done")
gen_project("large", sizes.large)
print("  large (1000 files): done")
gen_huge()
print("  huge (10000 files): done")
gen_monorepo()
print("  monorepo (500 files, 10 packages): done")
gen_worstcase()
print("  worstcase (16 files, 4550-line massive generics + 50 errors): done")

print("\nAll projects ready.")
