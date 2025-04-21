#!/usr/bin/env python3
"""
generate_ssdt.py - Compile an ACPI .asl file into .c and .h using iasl

Usage:
    python3 generate_ssdt.py /full/path/to/PoeFanSsdt.asl
"""

import subprocess
import sys
from pathlib import Path


IASL_CMD = "iasl"



def check_tool_available(cmd):
    try:
        subprocess.run([cmd, "-v"], check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    except Exception:
        print(f"[ERROR] Required tool '{cmd}' not found in PATH.")
        sys.exit(1)


def should_rebuild(asl_file: Path, c_file: Path) -> bool:
    if not c_file.exists() :
        return True
    return asl_file.stat().st_mtime > c_file.stat().st_mtime


def format_file(file_path: Path):
    if not file_path.exists():
        print(f"[ERROR] Expected output file {file_path} was not generated.")
        return False
    with file_path.open("r") as f:
        lines = f.readlines()

    cleaned = []
    for line in lines:
        stripped = line.rstrip()
        if stripped or (cleaned and cleaned[-1].strip()):
            cleaned.append(stripped + "\n")

    with file_path.open("w") as f:
        f.writelines(cleaned)

    print(f"[✓] Formatted: {file_path.name}")
    return True


def compile_with_iasl(asl_path: Path, base_output: Path):
    print(f"[+] Running: iasl -vs -tc -p {base_output} {asl_path}")
    try:
        subprocess.run(
            [IASL_CMD, "-vs", "-tc", "-p", str(base_output), str(asl_path)],
            check=True
        )
    except subprocess.CalledProcessError as e:
        print(f"[ERROR] iasl failed with exit code {e.returncode}")
        sys.exit(e.returncode)

    hex_file = base_output.with_suffix(".hex")
    c_file = base_output.with_suffix(".c")

    if not hex_file.exists():
        print(f"[ERROR] Expected .hex file not generated: {hex_file}")
        sys.exit(1)

    # Add the size of the array as a definition in the generated C file
    hex_file.rename(c_file)
    print(f"[✓] Renamed {hex_file} to {c_file}")

    try:
        with c_file.open("r+") as output:
            lines = output.readlines()
            # Insert the length definition before the #endif
            for i, line in enumerate(lines):
                if line.strip() == "#endif":
                    lines.insert(i, 'unsigned int poefanssdt_aml_code_len = sizeof(poefanssdt_aml_code);\n')
                    break
            output.seek(0)
            output.writelines(lines)
        print(f"[✓] Added AML code length definition to {c_file.name}")
    except Exception as e:
        print(f"[ERROR] Failed to add AML code length definition to {c_file.name}: {e}")
        sys.exit(1)




def main():
    if len(sys.argv) != 2:
        print("Usage: python3 generate_ssdt.py /full/path/to/PoeFanSsdt.asl")
        sys.exit(1)

    asl_path = Path(sys.argv[1]).resolve()
    if not asl_path.exists():
        print(f"[ERROR] File not found: {asl_path}")
        sys.exit(1)

    base = asl_path.with_suffix("")  # PoeFanSsdt
    c_path = base.with_suffix(".c")
    aml_path = base.with_suffix(".aml")

    print("[*] ACPI SSDT Generator")

    check_tool_available(IASL_CMD)


    if not should_rebuild(asl_path, c_path):
        print("[✓] Up to date. No rebuild needed.")
        return

    compile_with_iasl(asl_path, base)

    if not c_path.exists():
            print("[ERROR] .c file not generated.")
            sys.exit(1)

  
    format_file(c_path)

    print("[✓] SSDT generation complete.")


if __name__ == "__main__":
    main()
