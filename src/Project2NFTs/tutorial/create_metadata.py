
import json

IMG_BASE = "ipfs://QmT1ynMiR2VytDycMmQBZCcAj2SwrwEh8fjuLRk36Qw9Vd/{}.jpg"
METADATA_FOLDER = "/Users/pbharrin/Downloads/metadata/"

IMG_DATA = [
    ('Frog', 'CH'),
    ('Turtle', 'CH'),
    ('Sun', 'CH'),
    ('Rudolph', 'CH'),
    ('Leprechaun', 'CH'),
    ('Frosty', 'CH'),
    ('Abe Lincoln', 'CH'),
    ('Girl', 'CH'),
    ('Beaker', 'JH'),
    ('Naughty Elf', 'JH'),
    ('Happy Leprechaun', 'JH'),
    ('Creeper', 'JH'),
    ('Flowers', 'JH'),
    ("Dr. Frankenstein's Monster", 'JH'),
    ('Rainbow 1', 'CH'),
    ('Rainbow 2', 'CH'),
]

if __name__ == "__main__":
    for i, row in enumerate(IMG_DATA):
        d = {
            "image": IMG_BASE.format(i),
            "name": row[0],
            "description": f"made by: {row[1]}"
        }

        print(json.dumps(d, indent=2))
        fw = open(METADATA_FOLDER + f"{i}", 'w')
        fw.write(json.dumps(d, indent=2))
        fw.close()