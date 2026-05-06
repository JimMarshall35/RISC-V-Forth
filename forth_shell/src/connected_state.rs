use std::time::Duration;

use crossterm::event::{self, KeyCode, KeyEventKind};
use ratatui::layout::{Constraint, Layout, Position, Direction};
use ratatui::style::{Color, Modifier, Style, Stylize};
use ratatui::text::{Line, Span, Text};
use ratatui::widgets::{Block, List, ListItem, ListState, Paragraph};
use ratatui::{Frame};

use crate::device_connection_states::{DeviceConnectionState, DeviceConnectionStateImplementation};
use crate::Args;
use crate::forth_state::ForthState;

enum InputMode {
    Normal,
    Editing,
}

pub struct ConnectedState {
    /// Current value of the input box
    input: String,
    /// Position of cursor in the editor area.
    character_x: usize,
    character_y: usize,
    /// Current input mode
    input_mode: InputMode,
    scroll_serialterm: u16,
    serialtermHeight: u16,
    next_state: DeviceConnectionState,
    dictionary_list_state: ListState
}

impl ConnectedState {

    pub fn new(args: &Args) -> Self {
        Self {
            input: String::new(),
            character_x: 0,
            character_y: 0,
            input_mode: InputMode::Normal,
            scroll_serialterm: 0,
            serialtermHeight: 0,
            next_state: DeviceConnectionState::Connected,
            dictionary_list_state: ListState::default()
        }
    }

    fn move_cursor_left(&mut self) {
        self.character_x -= 1;
    }

    fn move_cursor_down(&mut self) {
        self.character_y += 1;
        if self.character_y >= (self.serialtermHeight - 2) as usize {
           // print!("LOLOL");
            self.character_y = (self.serialtermHeight - 3) as usize;
        }
    }

    fn carriage_return(&mut self) {
        self.character_x = 0;
    }
    fn move_cursor_right(&mut self) {
        self.character_x += 1;
    }

    fn enter_char(&mut self, new_char: char) {
        self.input.push(new_char);
        self.move_cursor_right();
    }

    fn scroll_down(&mut self) {
        self.scroll_serialterm = self.scroll_serialterm.saturating_add(1);
    }

    fn scroll_up(&mut self) {
        self.scroll_serialterm = self.scroll_serialterm.saturating_sub(1);
    }
    
    fn delete_char(&mut self) {
        let is_not_cursor_leftmost = self.character_x != 0;
        if is_not_cursor_leftmost {
            self.input.pop();
            self.move_cursor_left();
        }
    }

    fn get_top_msg(&mut self) -> (Vec<Span<'static>>, Style) {
        match self.input_mode {
            InputMode::Normal => (
                vec![
                    "Press ".into(),
                    "q".bold(),
                    " to exit, ".into(),
                    "e".bold(),
                    " to start editing.".bold(),
                ],
                Style::default().add_modifier(Modifier::RAPID_BLINK),
            ),
            InputMode::Editing => (
                vec![
                    "Press ".into(),
                    "Esc".bold(),
                    " to stop editing, ".into(),
                    "Enter".bold(),
                    " to record the message".into(),
                ],
                Style::default(),
            ),
        }
    }
}

impl DeviceConnectionStateImplementation for ConnectedState {
    
    fn handle_input(&mut self, port: &mut dyn serialport::SerialPort) -> bool {
        if event::poll(Duration::from_millis(30)).unwrap() {
            if let Some(key) = event::read().unwrap().as_key_press_event() {
                match self.input_mode {
                    InputMode::Normal => match key.code {
                        KeyCode::Char('e') => {
                            self.input_mode = InputMode::Editing;
                        }
                        KeyCode::Char('q') => {
                            return true;
                        }
                        _ => {}
                    },
                    InputMode::Editing if key.kind == KeyEventKind::Press => match key.code {
                        KeyCode::Enter => {
                            let v :Vec<u8> = vec![ 13 as u8 ];
                            match port.write(&v) {
                                Ok(_) => {},
                                Err(_) => {
                                    self.next_state = DeviceConnectionState::EstablishingSerialPortConnection;
                                },
                            };
                        },
                        KeyCode::Char(to_insert) => {
                            let v :Vec<u8> = vec![ to_insert as u8 ];
                            match port.write(&v) {
                                Ok(_) => {},
                                Err(_) => {
                                    self.next_state = DeviceConnectionState::EstablishingSerialPortConnection;
                                },
                            };
                        },
                        KeyCode::Backspace => {
                            let v :Vec<u8> = vec![ 8 as u8 ];
                            match port.write(&v) {
                                Ok(_) => {},
                                Err(_) => {
                                    self.next_state = DeviceConnectionState::EstablishingSerialPortConnection;
                                },
                            };
                        },
                        KeyCode::Down => self.scroll_down(),
                        KeyCode::Up => self.scroll_up(),
                        KeyCode::Esc => self.input_mode = InputMode::Normal,
                        _ => {}
                    },
                    InputMode::Editing => {}
                }
            }
        }
        return false;
    }
    
    fn read_serial(&mut self, mut port: &mut dyn serialport::SerialPort, forth_state: &mut ForthState) {
        let mut buf: [u8; 128] = [0; 128];
        match port.read(buf.as_mut_slice()) {
            Ok(value) => {
                for i in 0..value {
                    if buf[i] == 8 {
                        self.delete_char();
                        
                    }
                    else if buf[i] == 13 {
                        self.move_cursor_down();
                        self.carriage_return();
                    }
                    else {
                        self.enter_char(buf[i] as char);
                    }
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

    fn render(&mut self, frame: &mut Frame, forth_state: &ForthState) {
        let outer_chunks = Layout::default()
            .direction(Direction::Vertical)
            .constraints([
                Constraint::Length(1),
                Constraint::Min(0),
            ])
            .split(frame.size());

        let inner_chunks = Layout::default()
            .direction(Direction::Horizontal)
            .constraints([
                Constraint::Percentage(70),
                Constraint::Percentage(30),
            ])
            .split(outer_chunks[1]);

        let (msg, style) = self.get_top_msg();
        let mut inputCpy = self.input.clone();
        inputCpy += " ";
        let total_lines = inputCpy.lines().count() as u16;

        let visible_height = inner_chunks[0].height.saturating_sub(2); // minus borders if any
        self.serialtermHeight = inner_chunks[0].height;

        // 👇 auto-scroll so bottom is visible
        if total_lines > visible_height {
            self.scroll_serialterm = total_lines - visible_height ;
        } else {
            self.scroll_serialterm = 0;
        }

        let text = Text::from(Line::from(msg)).patch_style(style);
        let help_message = Paragraph::new(text);
        frame.render_widget(help_message, outer_chunks[0]);

        let input = Paragraph::new(self.input.as_str())
            .style(match self.input_mode {
                InputMode::Normal => Style::default(),
                InputMode::Editing => Style::default().fg(Color::Yellow),
            })
            .block(Block::bordered().title("Input"))
            .scroll((self.scroll_serialterm, 0));
        frame.render_widget(input, inner_chunks[0]);
        match self.input_mode {
            // Hide the cursor. `Frame` does this by default, so we don't need to do anything here
            InputMode::Normal => {}
            #[expect(clippy::cast_possible_truncation)]
            InputMode::Editing => frame.set_cursor_position(Position::new(
                // Draw the cursor at the current position in the input field.
                // This position can be controlled via the left and right arrow key
                inner_chunks[0].x + self.character_x as u16 + 1,
                // Move one line down, from the border to the input line
                inner_chunks[0].y + self.character_y as u16 + 1,
            )),
        }

        let mut wordVals: Vec<ListItem> = vec![];
        for (key, value) in forth_state.words.iter() {
            let v = format!("{} {}", key, value.address);
            wordVals.push(ListItem::new(v));
        }
        let words = List::new(wordVals).block(Block::bordered().title("Dictionary"));
        frame.render_stateful_widget(words, inner_chunks[1], &mut self.dictionary_list_state);
    }

    fn on_enter_state(&mut self, port: &mut dyn serialport::SerialPort, forth_state: &mut ForthState) {
        self.input.clear();
        self.scroll_serialterm = 0;
        self.character_x = 0;
        self.character_y = 0;
        self.input_mode = InputMode::Normal;
    }

    fn on_exit_state(&mut self) {
        self.next_state = DeviceConnectionState::Connected;
    }

    fn next_state(&mut self) -> DeviceConnectionState {
        return self.next_state.clone();
    }
}