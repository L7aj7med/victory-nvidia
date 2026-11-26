//! Local tool: prints the console programs of a shader container as SP3 text.
use victory_shader::{Container, FourCC};
fn main() {
    let path = std::env::args().nth(1).expect("container path");
    let data = std::fs::read(&path).expect("read");
    let c = Container::parse(&data).expect("container");
    let part = c.part(FourCC::DXIL).or(c.part(FourCC::ACCC)).expect("no DXIL/ACCC part");
    for p in victory_shader::native_programs(part.data).expect("programs") {
        println!("; stage {:?} wave64 {} vgprs {}", p.stage, p.wave64, p.vgprs);
        for i in victory_shader::gfx10::decode(&p.code).expect("decode") {
            println!("{:5x}: {}", i.offset, i.text(p.wave64));
        }
    }
}
