import re
import os
def parse_ability_special(ability_special_text):
    """
    Parse the 'AbilitySpecial' section from the old format.
    """
    # Regex to extract each special block, allowing for comments after the block number
    special_pattern = re.compile(r'"(\d+)"(?:\s*//[^\n]*)?\s*\{([^}]+)\}', re.DOTALL)
    specials = []

    # Find all special entries
    for match in special_pattern.finditer(ability_special_text):
        block = match.group(2)
        special_block = {}
        for line in block.splitlines():
            line = line.strip()
            if line:
                # Remove comments but keep the content before the comment
                line = re.sub(r'//.*', '', line).strip()
                # Extract key-value pairs
                parts = re.findall(r'"(.*?)"', line)
                if len(parts) == 2:
                    key, value = parts
                    special_block[key] = value
        specials.append(special_block)
    
    return specials

def convert_to_ability_values(specials):
    """
    Convert parsed specials into the new 'AbilityValues' format.
    """
    ability_values = {}

    for special in specials:
        value_key = None
        linked_bonus_key = None
        requires_scepter = special.get("RequiresScepter", None)
        requires_shard = special.get("RequiresShard", None)
        calculate_spell_damage_tooltip = special.get("CalculateSpellDamageTooltip", None)
        affected_by_aoe_increase = special.get("affected_by_aoe_increase", None)
        linked_bonus_field = special.get("LinkedSpecialBonusField", None)
        linked_bonus_operation = special.get("LinkedSpecialBonusOperation", None)
        ad_linked_abilities = special.get("ad_linked_abilities", None)
        damage_type_tooltip = special.get("DamageTypeTooltip", None)  # Add this line

        for key, value in special.items():
            if key == "LinkedSpecialBonus":
                linked_bonus_key = value
            elif key != "var_type" and key not in ["RequiresScepter", "RequiresShard", "CalculateSpellDamageTooltip", "affected_by_aoe_increase", "LinkedSpecialBonusField", "LinkedSpecialBonusOperation", "ad_linked_abilities", "DamageTypeTooltip"]:
                value_key = key

        if value_key:
            nested_value = {"value": special[value_key]}
            if linked_bonus_key:
                nested_value["LinkedSpecialBonus"] = linked_bonus_key
            if requires_scepter:
                nested_value["RequiresScepter"] = requires_scepter
            if requires_shard:
                nested_value["RequiresShard"] = requires_shard
            if calculate_spell_damage_tooltip:
                nested_value["CalculateSpellDamageTooltip"] = calculate_spell_damage_tooltip
            if affected_by_aoe_increase:
                nested_value["affected_by_aoe_increase"] = affected_by_aoe_increase
            if linked_bonus_field:
                nested_value["LinkedSpecialBonusField"] = linked_bonus_field
            if linked_bonus_operation:
                nested_value["LinkedSpecialBonusOperation"] = linked_bonus_operation
            if ad_linked_abilities:
                nested_value["ad_linked_abilities"] = ad_linked_abilities
            if damage_type_tooltip:  # Add this block
                nested_value["DamageTypeTooltip"] = damage_type_tooltip

            # Create a nested structure if there's any additional information
            if any([linked_bonus_key, requires_scepter, requires_shard, calculate_spell_damage_tooltip, affected_by_aoe_increase, linked_bonus_field, linked_bonus_operation, ad_linked_abilities, damage_type_tooltip]):
                ability_values[value_key] = nested_value
            else:
                ability_values[value_key] = special[value_key]

    return ability_values

def format_ability_values(ability_values):
    """
    Format the 'AbilityValues' dictionary into the desired KV format with proper indentation.
    The entire block inside "AbilityValues" is indented by 8 spaces.
    """
    formatted_text = '"AbilityValues"\n        {\n'
    for key, value in ability_values.items():
        if isinstance(value, dict):
            formatted_text += f'            "{key}"\n            {{\n'
            for sub_key, sub_value in value.items():
                formatted_text += f'                "{sub_key}" "{sub_value}"\n'
            formatted_text += '            }\n'
        else:
            formatted_text += f'            "{key}" "{value}"\n'
    formatted_text += '        }'
    return formatted_text


def convert_ability_special_to_new_format(ability_special_text):
    """
    Convert old 'AbilitySpecial' to new 'AbilityValues'.
    """
    specials = parse_ability_special(ability_special_text)
    new_ability_values = convert_to_ability_values(specials)

    return format_ability_values(new_ability_values)


def process_file(input_filename, output_filename):
    with open(input_filename, 'r', encoding='utf-8') as file:
        content = file.read()

    # Find the AbilitySpecial block
    ability_special_pattern = re.compile(r'("AbilitySpecial"\s*{(?:[^{}]*|{(?:[^{}]*|{[^{}]*})*})*})', re.DOTALL)
    
    def replace_ability_special(match):
        ability_special_text = match.group(1)
        new_ability_values = convert_ability_special_to_new_format(ability_special_text)
        return new_ability_values

    # Replace AbilitySpecial with AbilityValues
    new_content = ability_special_pattern.sub(replace_ability_special, content)

    # Write the modified content to the output file
    os.makedirs(os.path.dirname(output_filename), exist_ok=True)
    with open(output_filename, 'w', encoding='utf-8') as file:
        file.write(new_content)

    print(f"Processed {input_filename} and saved results to {output_filename}")

def process_all_files_in_folder():
    # Get the directory of the script
    script_dir = os.path.dirname(os.path.abspath(__file__))

    # Create an 'output' folder if it doesn't exist
    output_dir = os.path.join(script_dir, 'output')
    if not os.path.exists(output_dir):
        os.makedirs(output_dir)

    # Process all .txt files in the script's directory and subdirectories
    for root, dirs, files in os.walk(script_dir):
        # Exclude the output directory
        if 'output' in dirs:
            dirs.remove('output')
        
        for filename in files:
            if filename.endswith('.txt'):
                input_path = os.path.join(root, filename)
                # Create a relative path for the output file
                rel_path = os.path.relpath(root, script_dir)
                output_path = os.path.join(output_dir, rel_path, filename)
                process_file(input_path, input_path)

# Run the script to process all .txt files in the same folder and subfolders
if __name__ == "__main__":
    process_all_files_in_folder()
