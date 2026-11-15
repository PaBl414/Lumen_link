"""Independent little-endian v3 fixtures; does not call the Godot codec."""
import json, struct
from pathlib import Path
pack=struct.pack
ping=pack('<4sHBBIIIH',b'LMLK',3,12,0,1,2,3,8)+pack('<Q',1000)
body=pack('<IIHHBBBBbB',10,10,10800,180,6,0,0,0,-1,0)
body+=pack('<3HHBBIBIB',0,0,0,0,0,0,0,0,0,0)
body+=pack('<B',4)+b'dock'+pack('<HH',0,0)
assert len(body)==47
for x in [112.,176.]:body+=pack('<6f5B3H',x,592.,0.,0.,1.,0.,0,0,0,0,0,0,0,0)
assert len(body)==117
Path('tests/fixtures/protocol_vectors.json').write_text(json.dumps(dict(ping_hex=ping.hex(),snapshot_body_hex=body.hex(),generator='independent Python struct little endian; protocol3 snapshot base113+ID bytes; players35 B; player0 offset43+ID bytes'),indent=2)+'\n')
