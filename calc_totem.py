# Let's calculate Level 3 Vitality for Totem
# Base Vitality by level in DOS2:
def get_vitality_boost(level):
    starting = 21.0
    linear = 9.091
    exp_growth = 1.25
    growth = exp_growth ** (level - 1)
    raw = level * linear + starting * growth
    return round(round(raw) / 5.0) * 5

lvl3_base = get_vitality_boost(3)
print(f"Level 3 Vitality Boost: {lvl3_base}")

# Totems in vanilla have a Vitality stat percentage in Character.txt:
# Usually Totems have Vitality = 15 (or 20, 25, etc.) or inherit from _Base/Totem archetype
# Let's check summoning bonus: each point in Summoning adds +10% Vitality/Armor/Damage
# For Summoning = 2, bonus is +20% (1.20x)
