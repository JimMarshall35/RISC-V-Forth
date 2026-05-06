use crate::device_connection_states::DeviceConnectionStateImplementation;
use crate::forth_state::{ForthState, ForthWord};
use crossterm::event::{self, KeyCode, KeyEventKind};
use std::time::Duration;
use ratatui::widgets::{Block, Clear, Paragraph};
use ratatui::layout::{Constraint, Layout};
use regex::Regex;
use crate::device_connection_states::DeviceConnectionState;
use std::time::Instant;

pub struct InitialHandshakeState {
    // data recieved from serial while in this state
    input: String,
    next_state: DeviceConnectionState,
    timer: Instant
}

impl InitialHandshakeState {
    pub fn new() -> Self {
        Self {
            next_state: DeviceConnectionState::InitialHandshake,
            input: String::new(),
            timer: Instant::now(),
        }
    }
}

impl DeviceConnectionStateImplementation for InitialHandshakeState {
    fn handle_input(&mut self, port: &mut dyn serialport::SerialPort) -> bool {
        if event::poll(Duration::from_millis(30)).unwrap() {
            if let Some(key) = event::read().unwrap().as_key_press_event() {
                match key.code {
                    KeyCode::Char('q') => {
                        return true;
                    },
                    _ => {}
                }
            }
        }
        
        return false;
    }

    fn read_serial(&mut self, port:&mut dyn serialport::SerialPort, forth_state: &mut ForthState) {
        let mut buf: [u8; 128] = [0; 128];
        match port.read(buf.as_mut_slice()) {
            Ok(value) => {
                for i in 0..value {
                    self.input.push(buf[i] as char);
                }
            }
            Err(ref e) if e.kind() == std::io::ErrorKind::TimedOut => {
                // no data available right now
            }
            Err(e) => {
                self.next_state = DeviceConnectionState::EstablishingSerialPortConnection;
            }
        }
        let elapsed = self.timer.elapsed().as_millis();
        if elapsed > 2000 {
            // showword should have finished
            let lines = self.input.lines().skip(1);
            for line in lines {
                let tokens: Vec<&str> = line.trim().split_whitespace().collect();
                let addr: u32 = u32::from_str_radix(tokens[0].trim_start_matches("0x"), 16).unwrap();
                forth_state.words.insert(tokens[1].to_string(), ForthWord { name: tokens[1].to_string(), address: addr});
            }
            if forth_state.words.len() > 0 {
                self.next_state = DeviceConnectionState::Connected;
            }
            else {
                self.next_state = DeviceConnectionState::EstablishingSerialPortConnection;
            }
        }
    }

    fn render(&mut self, frame: &mut ratatui::Frame, forth_state: &ForthState) {
        let area = frame.area();
        let popup_block = Block::bordered().title("Connection");
        let centered_area = area.centered(Constraint::Percentage(60), Constraint::Percentage(20));
        // clears out any background in the area before rendering the popup
        frame.render_widget(Clear, centered_area);
        let paragraph = Paragraph::new("Requesting Data From MCU").block(popup_block);
        frame.render_widget(paragraph, centered_area);
    }

    fn on_enter_state(&mut self, port: &mut dyn serialport::SerialPort, forth_state: &mut ForthState) {
        self.next_state = DeviceConnectionState::InitialHandshake;
        self.input.clear();
        let cmd = "showWords\r";
        self.timer = Instant::now();
        port.write(cmd.as_bytes());
        forth_state.words.clear();
    }

    fn on_exit_state(&mut self) {

    }

    fn next_state(&mut self) -> DeviceConnectionState {
        return self.next_state.clone();
    }
}
