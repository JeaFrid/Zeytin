import os

def generate_project_index(output_file):
    excluded_dirs = {
        '.git', 
        '.idea', 
        '.vscode', 
        '__pycache__',
        'node_modules', 
        'build', 
        '.dart_tool',
        'dist',
        'venv',
        "zeytin", "zeytin_err"
        'env', "lock"
    }

    excluded_extensions = {
        '.png', '.jpg', '.jpeg', '.gif', '.ico', '.svg','.env',
        '.pdf', '.exe', '.dll', '.so', '.dylib', 
        '.zip', '.tar', '.gz', '.7z',
        '.pyc', '.class'
    }

    excluded_files = {
        output_file,
        "revani.db", "revani", "revani.exe",
        'project_indexer.py',
        '.DS_Store', "server.crt", "server.key", "test.py",
        'package-lock.json',
        "analysis_options.yaml",
        "cert.pem", "key.pem","analysis_options.yaml","Dockerfile","pubspec.lock",".dockerignore",
        "pubspec.lock",
        'yarn.lock'
    }

    current_dir = os.getcwd()

    with open(output_file, 'w', encoding='utf-8') as out_f:
        for root, dirs, files in os.walk(current_dir):
            dirs[:] = [d for d in dirs if d not in excluded_dirs]

            for file in files:
                if file in excluded_files:
                    continue

                if any(file.endswith(ext) for ext in excluded_extensions):
                    continue

                file_path = os.path.join(root, file)
                relative_path = os.path.relpath(file_path, current_dir)

                separator = f"\n\n{'='*60}\nFILE: {relative_path}\n{'='*60}\n\n"
                out_f.write(separator)

                try:
                    with open(file_path, 'r', encoding='utf-8', errors='replace') as in_f:
                        content = in_f.read()
                        out_f.write(content)
                except Exception as e:
                    out_f.write(f"[ERROR READING FILE] - {str(e)}")

if __name__ == "__main__":
    output_filename = 'full_project_index.txt'
    generate_project_index(output_filename)
    print(f"Operation completed successfully. Output saved to {output_filename}")