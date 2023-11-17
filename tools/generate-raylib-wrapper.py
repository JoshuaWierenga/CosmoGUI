import argparse
from dataclasses import dataclass
import pathlib
import re
import shutil
import subprocess
import tempfile

# TODO Support vararg functions
# TODO Display subsections
# TODO Display comments

@dataclass
class CFunctionParameter:
    decl: str
    name: str

@dataclass
class CFunction:
    name: str
    returnType: str
    parameters: list[CFunctionParameter]

raylibFunctions: dict[str, list[CFunction]] = dict()

currentSection = ''

with open('third_party/raylib/src/raylib.h', 'r') as raylib:
    for line in raylib:
        if not line:
            break
        
        if line.startswith('// ') and '(Module: ' in line:
            currentSection = line[3:].rstrip()
            raylibFunctions[currentSection] = list()
            print(f'\nFound section: {currentSection}\n')
        
        
        if line.startswith('RLAPI ') and ');' in line:
            line = line[6:].split(';')[0]

            #print(line)

            functionName = re.search(r'(\w+)\(', line).group(1)
            returnType = re.search(r'^[\w* ]+[^\w(]', line).group(0)

            if '...' in line:
                continue

            if '(void)' in line:
                parameters = [CFunctionParameter('void', '')]
            else:
                parameters = list(CFunctionParameter(p.group(0)[:-1], p.group(1)) for p in re.finditer(r'\w[\w ]+ \**(\w+)[,)]', line))

            print('Found function: ', returnType, functionName, '(', ', '.join(p.decl for p in parameters), ')', sep='')

            raylibFunctions[currentSection].append(CFunction(functionName, returnType, parameters))

if len(raylibFunctions) == 0:
    exit(1)

with open('src/generated/raylib-wrapper.c', 'w+') as wrapper:
    wrapper.write('''#include <dlfcn.h>
#include <raylib.h>
#include <stdlib.h>

wontreturn void defaultFunc(const char *name) {
  fprintf(stderr, "FATAL: Function is not loaded: %s\\n", name);
  exit(1);
}

#define wrapFunction(libName, returnType, name, parameters, parameterNames) \\
returnType (*P ## name)parameters = NULL;\\
returnType name parameters {\\
  if (!P ## name) {\\
    defaultFunc(#name);\\
  }\\
  fprintf(stderr, "INFO: Calling " # libName " function: " # name "\\n");\\
  return P ## name parameterNames;\\
}

#define loadLibrary(var, name, path, mode) \\
void *var = cosmo_dlopen(path, mode);\\
if (!var) {\\
  fprintf(stderr, "%s\\n", dlerror());\\
  exit(1);\\
} else {\\
  fprintf(stderr, "INFO: Loaded required library: " # name "\\n");\\
}

#define loadFunction(lib, name)\\
P ## name = cosmo_dlsym(lib, #name);\\
if (!P ## name) {\\
  fprintf(stderr, "ERROR: Failed to load required function: " # name ": %s\\n", dlerror());\\
} else {\\
  fprintf(stderr, "INFO: Loaded required function: " # name "\\n");\\
}
''')

    #'''
    for module, functions in raylibFunctions.items():
        wrapper.write(f'''
//------------------------------------------------------------------------------------
// {module}
//------------------------------------------------------------------------------------

''')
        for function in functions:
            wrapper.write(f"wrapFunction(Raylib, {function.returnType.rstrip()}, {function.name}, ({', '.join(p.decl for p in function.parameters)}), ({', '.join(p.name for p in function.parameters)}))\n")
    #'''

    wrapper.write('''

void initRaylibWrapper(char *libPath) {
  loadLibrary(pLibRaylib, Raylib, libPath, RTLD_LAZY);

''')

    for module, functions in raylibFunctions.items():
        wrapper.write(f'''
  //------------------------------------------------------------------------------------
  // {module}
  //------------------------------------------------------------------------------------

''')
        for function in functions:
            wrapper.write(f"  loadFunction(pLibRaylib, {function.name});\n")

    wrapper.write('}\n')


#with open('src/generated/raylib-wrapper.h', 'w+') as wrapper:
#    wrapper.write('#include <raylib.h>\n')
#    for module, function in raylibFunctions.items():
#        wrapper.write(f'''
#//------------------------------------------------------------------------------------
#// {module}
#//------------------------------------------------------------------------------------
#
#''')
#        for function in functions:
#            wrapper.write(f"{returnType}{functionName}(, ', '.join(p.decl for p in parameters), ')'\n")