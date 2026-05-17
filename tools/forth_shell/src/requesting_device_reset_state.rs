use crate::device_connection_states::DeviceConnectionStateImplementation;
use crate::forth_state::ForthState;
use crossterm::event::{self, KeyCode, KeyEventKind};
use std::time::Duration;
use ratatui::widgets::{Block, Clear, Paragraph};
use ratatui::layout::{Constraint, Layout};
use regex::Regex;
use crate::device_connection_states::DeviceConnectionState;

pub struct RequestingDeviceResetState {
    // data recieved from serial while in this state
    input: String,
    next_state: DeviceConnectionState
}

impl RequestingDeviceResetState {
    pub fn new() -> Self {
        Self {
            next_state: DeviceConnectionState::RequestingDeviceReset,
            input: String::new()
        }
    }
}

impl DeviceConnectionStateImplementation for RequestingDeviceResetState {
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

                let regex_patterns = [
                    Regex::new(r"data stack base:\s*(0x[0-9A-Fa-f]{8})").unwrap(),
                    Regex::new(r"return stack base:\s*(0x[0-9A-Fa-f]{8})").unwrap(),
                    Regex::new(r"instruction ptr:\s*(0x[0-9A-Fa-f]{8})").unwrap(),
                    Regex::new(r"memory end:\s*(0x[0-9A-Fa-f]{8})").unwrap(),
                    Regex::new(r"dict end:\s*(0x[0-9A-Fa-f]{8})").unwrap(),
                ];
                let mut matches = 0;
                let len = regex_patterns.len();

                let s: String = self.input.chars().collect();
                for r in regex_patterns {
                    if let Some(caps) = r.captures(&s) {
                        let value = caps.get(1).unwrap().as_str();
                        matches += 1;
                    }
                }
                if matches == len {
                    self.next_state = DeviceConnectionState::InitialHandshake;
                }

            }
            Err(ref e) if e.kind() == std::io::ErrorKind::TimedOut => {
                // no data available right now
            }
            Err(e) => {
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
        let paragraph = Paragraph::new("Please  press reset on MCU").block(popup_block);
        frame.render_widget(paragraph, centered_area);
    }

    fn on_enter_state(&mut self, port:&mut dyn serialport::SerialPort, forth_state: &mut ForthState) {
        self.next_state = DeviceConnectionState::RequestingDeviceReset;
        self.input.clear();
    }

    fn on_exit_state(&mut self) {

    }

    fn next_state(&mut self) -> DeviceConnectionState {
        return self.next_state.clone();
    }
}

