use std::io::{self, Write, stdout};
use std::thread;
use clap::Parser;
use std::time::Duration;
use crossterm::event::{Event, KeyCode, KeyEvent, poll, read };
use crossterm::terminal::{enable_raw_mode, disable_raw_mode};
use crossterm::{cursor, execute};

#[derive(Parser, Debug)]
#[command(version, about)]
struct Args {
    /// Serial port (e.g. /dev/ttyUSB0 or COM3)
    #[arg(short, long)]
    port: String,
}

fn should_send_keypress(e : &KeyEvent) -> bool {
    let mut r = true;
    if e.code == KeyCode::Left ||
        e.code == KeyCode::Right ||
        e.code == KeyCode::Up ||
        e.code == KeyCode::Down {
        // not supported yet
        r = false;
    }
    r
}

fn main() -> io::Result<()> {
    let args = Args::parse();
    
    let mut port = serialport::new(args.port, 115_200)
        .timeout(Duration::from_millis(30))
        .open()
        .expect("Failed to open port");
    enable_raw_mode()?;
    loop {
        if poll(Duration::from_millis(0))? {
            if let Event::Key(event) = read()? {
                if should_send_keypress(&event) {
                    match event.code {
                        KeyCode::Char(c) => {
                            let v :Vec<u8> = vec![ c as u8 ];
                    
                            port.write(&v);
                        }
                        KeyCode::Enter => {
                            let v :Vec<u8> = vec![ 13 as u8 ];
                            port.write(&v);
                        }
                        KeyCode::Backspace => {
                            let v :Vec<u8> = vec![ 8 as u8 ];
                            port.write(&v);
                        }
                        KeyCode::Esc => break,
                        _ => {}
                    }
                    
                }
            }
        }
        
        let mut serial_buf: Vec<u8> = vec![0; 128];
        match port.read(serial_buf.as_mut_slice()) {
            Ok(value) => {
                for i in 0..value {
                    if serial_buf[i] == 8 {
                        
                        let mut out = stdout();

                        execute!(
                            out,
                            cursor::MoveLeft(1),
                            crossterm::terminal::Clear(crossterm::terminal::ClearType::FromCursorDown)
                        )?;

                        out.flush().unwrap();
                    }
                    else {
                        print!("{}", serial_buf[i] as char);
                    }
                }
            }
            Err(_) => {}
        }
        thread::sleep(Duration::from_millis(20));
        io::stdout().flush().unwrap();
    }
    disable_raw_mode()?;
    Ok(())
}

