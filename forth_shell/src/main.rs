mod connected_state;
mod device_connection_states;
mod requesting_device_reset_state;
mod initial_handshake_state;
mod forth_state;

use color_eyre::Result;

use ratatui::{DefaultTerminal, Frame};
use ratatui::widgets::{Block, Clear, Paragraph};
use ratatui::layout::{Constraint};
use crossterm::event::{self, KeyCode};

use clap::Parser;
use std::time::Duration;
use serialport;


use crate::device_connection_states::{DeviceConnectionState, DeviceConnectionStateImplementation};
use crate::connected_state::ConnectedState;
use crate::requesting_device_reset_state::RequestingDeviceResetState;
use crate::forth_state::ForthState;
use crate::initial_handshake_state::InitialHandshakeState;

#[derive(Parser, Debug, Clone)]
#[command(version, about)]
struct Args {
    /// Serial port (e.g. /dev/ttyUSB0 or COM3)
    #[arg(short, long, default_value = "/dev/ttyUSB0")]
    port: String,
}


fn main() -> Result<()> {
    let args = Args::parse();

    color_eyre::install()?;
    ratatui::run(|terminal| App::new(&args).run(terminal))
}

/// App holds the state of the application
struct App {
    
    port: Option<Box<dyn serialport::SerialPort>>,
    connection_state: DeviceConnectionState,

    /*
        At the core of the app is the connection state machine

        1.) disconnected  <__________________________
                 |                    |              |
                 V                    | read failure |
        2.) request user resets MCU __|              | 
                 |                                   |
                 | (detects startup msg)             |
                 |                                   |
                 V                                   | read/write failure
        3.) initial handshake with mcu ______________|
                 |                                   |
                 | (recieve resonse to queries)      |                 
                 |                                   |
                 V                                   | read/write failure
        4.) fully connected__________________________|

        - state 1.) is implemented in the app class itself, because this class owns the serial port object
        - states 2 - 4 are implemeted as objects that implement DeviceConnectionStateImplementation
    */
    connected: Box<dyn DeviceConnectionStateImplementation>,
    requesting_reset: Box<dyn DeviceConnectionStateImplementation>,
    initial_handshake: Box<dyn DeviceConnectionStateImplementation>,
    args: Args,
    establishing_connection_next_state: DeviceConnectionState,
    forth_state: ForthState,
}


impl App {
    fn new(args: &Args) -> Self {
        Self {
            port: None,
            connection_state: DeviceConnectionState::EstablishingSerialPortConnection,
            // state implementations (se)
            connected: Box::new(ConnectedState::new(args)),
            requesting_reset: Box::new(RequestingDeviceResetState::new()),
            initial_handshake: Box::new(InitialHandshakeState::new()),
            args: args.clone(),
            establishing_connection_next_state: DeviceConnectionState::EstablishingSerialPortConnection,
            forth_state: ForthState::new()
        }
    }

    fn handle_input(&mut self) -> bool {
        match self.connection_state {
            DeviceConnectionState::EstablishingSerialPortConnection => {
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
            },
            DeviceConnectionState::RequestingDeviceReset => {
                if let Some(port) = self.port.as_mut() {
                    return self.requesting_reset.handle_input(port.as_mut());
                }
            },
            DeviceConnectionState::InitialHandshake => {
                if let Some(port) = self.port.as_mut() {
                    return self.initial_handshake.handle_input(port.as_mut());
                }
            },
            DeviceConnectionState::Connected => {
                if let Some(port) = self.port.as_mut() {
                    return self.connected.handle_input(port.as_mut());
                }
            }
        }
        return false;
    }

    fn read_serial(&mut self) {
        match self.connection_state {
            DeviceConnectionState::EstablishingSerialPortConnection => {
                match serialport::new(self.args.port.clone(), 115_200)
                    .timeout(Duration::from_millis(30))
                    .open()
                {
                    Ok(port) => {
                        self.port = Some(port);
                        self.establishing_connection_next_state = DeviceConnectionState::RequestingDeviceReset;
                    }
                    Err(_) => {
                        self.establishing_connection_next_state = DeviceConnectionState::EstablishingSerialPortConnection;
                    }
                }
            },
            DeviceConnectionState::RequestingDeviceReset => {
                if let Some(port) = self.port.as_mut() {
                    self.requesting_reset.read_serial(port.as_mut(), &mut self.forth_state);
                }

            },
            DeviceConnectionState::InitialHandshake => {
                if let Some(port) = self.port.as_mut() {
                    return self.initial_handshake.read_serial(port.as_mut(), &mut self.forth_state);
                }
            },
            DeviceConnectionState::Connected => {
                if let Some(port) = self.port.as_mut() {
                    self.connected.read_serial(port.as_mut(), &mut self.forth_state);
                }                
            }
        }
    }

    fn render_establishing_connection_screen(&mut self, frame: &mut Frame) {
        let area = frame.area();
        let popup_block = Block::bordered().title("Connection");
        let centered_area = area.centered(Constraint::Percentage(60), Constraint::Percentage(20));
        // clears out any background in the area before rendering the popup
        frame.render_widget(Clear, centered_area);
        let paragraph = Paragraph::new("Please connect MCU").block(popup_block);
        frame.render_widget(paragraph, centered_area);
        
    }

    fn next_state(&mut self) -> DeviceConnectionState {
        match self.connection_state {
            DeviceConnectionState::EstablishingSerialPortConnection => self.establishing_connection_next_state.clone(),
            DeviceConnectionState::RequestingDeviceReset => self.requesting_reset.next_state(),
            DeviceConnectionState::InitialHandshake => self.initial_handshake.next_state(),
            DeviceConnectionState::Connected => self.connected.next_state()
        }
    }

    fn on_enter_establish_serial_port_state(&mut self) {
        self.port = None;
    }

    fn on_exit_establish_serial_port_state(&mut self) {
        
    }

    fn draw(&mut self, terminal: &mut DefaultTerminal) {
        match self.connection_state {
            DeviceConnectionState::EstablishingSerialPortConnection => {
                terminal.draw(|frame| self.render_establishing_connection_screen(frame));
            },
            DeviceConnectionState::RequestingDeviceReset => {
                terminal.draw(|frame| self.requesting_reset.render(frame, &self.forth_state));
            },
            DeviceConnectionState::InitialHandshake => {
                terminal.draw(|frame| self.initial_handshake.render(frame, &self.forth_state));
            },
            DeviceConnectionState::Connected => {
                terminal.draw(|frame| self.connected.render(frame, &self.forth_state));
            }
        }
    }

    fn run(mut self, terminal: &mut DefaultTerminal) -> Result<()> {
        loop {
            
            let want_quit = self.handle_input();
            
            if want_quit {
                return Ok(());
            }

            self.read_serial();
            
            self.draw(terminal);
            let new_state = self.next_state();

            if new_state != self.connection_state {
                match self.connection_state {
                    DeviceConnectionState::EstablishingSerialPortConnection => self.on_exit_establish_serial_port_state(),
                    DeviceConnectionState::RequestingDeviceReset => self.requesting_reset.on_exit_state(),
                    DeviceConnectionState::InitialHandshake => self.initial_handshake.on_exit_state(),
                    DeviceConnectionState::Connected => self.connected.on_exit_state(),
                    
                }
                self.connection_state = new_state;
                let r = self.port.as_mut().unwrap().as_mut();
                match self.connection_state {
                    DeviceConnectionState::EstablishingSerialPortConnection => self.on_enter_establish_serial_port_state(),
                    DeviceConnectionState::RequestingDeviceReset => self.requesting_reset.on_enter_state(r, &mut self.forth_state),
                    DeviceConnectionState::InitialHandshake => self.initial_handshake.on_enter_state(r, &mut self.forth_state),
                    DeviceConnectionState::Connected => self.connected.on_enter_state(r, &mut self.forth_state),
                }
            }
        }
    }
}