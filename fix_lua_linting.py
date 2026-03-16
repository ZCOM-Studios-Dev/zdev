import os
import re

def fix_file_indentation(content):
    """Fix indentation issues in Lua files"""
    lines = content.split('\n')
    fixed_lines = []
    
    for line in lines:
        # Remove extra spaces at the beginning of lines
        stripped_line = line.lstrip()
        if stripped_line:  # Skip empty lines
            # Fix indentation to use 4 spaces consistently
            leading_spaces = len(line) - len(stripped_line)
            if leading_spaces > 0:
                # Normalize to multiples of 4 spaces
                normalized_spaces = (leading_spaces // 4) * 4
                line = ' ' * normalized_spaces + stripped_line
        
        fixed_lines.append(line)
    
    return '\n'.join(fixed_lines)

def fix_spacing_around_operators(content):
    """Fix spacing around operators like =, +, -, etc."""
    # Fix spacing around equals sign
    content = re.sub(r'([a-zA-Z0-9_])=(?!=)', r'\1 = ', content)
    content = re.sub(r'=(?!=)([a-zA-Z0-9_])', r' = \1', content)
    
    # Fix spacing around arithmetic operators
    content = re.sub(r'([a-zA-Z0-9_])\s*([+\-*/])\s*([a-zA-Z0-9_])', r'\1 \2 \3', content)
    
    # Fix spacing around comparison operators
    content = re.sub(r'([a-zA-Z0-9_])\s*(==|~=|<=|>=|<|>)\s*([a-zA-Z0-9_])', r'\1 \2 \3', content)
    
    return content

def fix_function_definitions(content):
    """Fix function definition formatting"""
    # Fix function declarations
    content = re.sub(r'(function\s+[a-zA-Z0-9_.]+\s*\()', r'\1', content)
    
    # Ensure consistent spacing after function keyword
    content = re.sub(r'function\s+(.+?)\s*\(', r'function \1(', content)
    
    return content

def fix_comments(content):
    """Fix comment formatting"""
    # Normalize comment spacing
    content = re.sub(r'(--+)\s*(.*)', r'\1 \2', content)
    
    return content

def fix_string_quotes(content):
    """Ensure consistent quote usage"""
    # Convert single quotes to double quotes where appropriate
    # Note: This is a basic approach, real implementation would be more complex
    return content

def fix_empty_lines(content):
    """Fix empty line issues"""
    lines = content.split('\n')
    fixed_lines = []
    prev_was_empty = False
    
    for line in lines:
        if not line.strip():
            if not prev_was_empty:
                fixed_lines.append('')
                prev_was_empty = True
        else:
            fixed_lines.append(line)
            prev_was_empty = False
    
    return '\n'.join(fixed_lines)

def process_lua_file(filepath):
    """Process a single Lua file to fix linting issues"""
    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            content = f.read()
        
        original_content = content
        
        # Apply fixes
        content = fix_file_indentation(content)
        content = fix_spacing_around_operators(content)
        content = fix_function_definitions(content)
        content = fix_comments(content)
        content = fix_empty_lines(content)
        
        # Write back if changed
        if content != original_content:
            with open(filepath, 'w', encoding='utf-8') as f:
                f.write(content)
            print(f"Fixed linting issues in: {filepath}")
        else:
            print(f"No linting issues found in: {filepath}")
            
    except Exception as e:
        print(f"Error processing {filepath}: {e}")

def main():
    """Main function to process all .lua files"""
    print("Starting Lua linting fix process...")
    
    # Process all .lua files in the project
    for root, dirs, files in os.walk('.'):
        for file in files:
            if file.endswith('.lua'):
                filepath = os.path.join(root, file)
                process_lua_file(filepath)
    
    print("Linting fix process completed!")

if __name__ == "__main__":
    main()
