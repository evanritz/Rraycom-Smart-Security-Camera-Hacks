import sys

HEADER = '==ROM READ START=='
FOOTER = '==ROM READ END=='

def main(args):

    print('Parsing ROM output file...')

    with open(args[0], 'r') as f:
        raw_content = f.readlines()
    
    iheader, ifooter = 0, 0
    for i, line in enumerate(raw_content):
        line = line.strip()
        if line == HEADER:
            iheader = i
        if line == FOOTER:
            ifooter = i

    if ifooter == 0 or iheader == 0:
        print('Header and/or Footer not found!')
        sys.exit(1)
    
    rom_content = raw_content[iheader+1:ifooter]

    print('Creating ROM File...')

    with open(args[1], 'wb') as f:
        for line in rom_content:
            line = line.strip()
            b = int(line, 16)
            f.write(bytes([b]))

    print('Done!')

if __name__ == '__main__':
    if len(sys.argv) != 3:
        print("Usage: python3 parse-rom-output.py <input-file> <output-file>")
        sys.exit(1)
    else:
        main(sys.argv[1:])