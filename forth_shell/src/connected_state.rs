use std::time::Duration;

use crossterm::event::{self, KeyCode, KeyEventKind};
use ratatui::layout::{Constraint, Layout, Position, Direction};
use ratatui::style::{Color, Modifier, Style, Stylize};
use ratatui::text::{Line, Span, Text};
use ratatui::widgets::{Block, Row, Table, TableState, Paragraph};
use ratatui::{Frame};

use crate::device_connection_states::{DeviceConnectionState, DeviceConnectionStateImplementation};
use crate::Args;
use crate::forth_state::ForthState;
use crate::showWords_parser::parse_showWords;

const banner: &str = "
    ██████                      █████    █████                        █████               ████  ████ 
   ███░░███                    ░░███    ░░███                        ░░███               ░░███ ░░███ 
  ░███ ░░░   ██████  ████████  ███████   ░███████              █████  ░███████    ██████  ░███  ░███ 
 ███████    ███░░███░░███░░███░░░███░    ░███░░███            ███░░   ░███░░███  ███░░███ ░███  ░███ 
░░░███░    ░███ ░███ ░███ ░░░   ░███     ░███ ░███           ░░█████  ░███ ░███ ░███████  ░███  ░███ 
  ░███     ░███ ░███ ░███       ░███ ███ ░███ ░███            ░░░░███ ░███ ░███ ░███░░░   ░███  ░███ 
  █████    ░░██████  █████      ░░█████  ████ █████ █████████ ██████  ████ █████░░██████  █████ █████
 ░░░░░      ░░░░░░  ░░░░░        ░░░░░  ░░░░ ░░░░░ ░░░░░░░░░ ░░░░░░  ░░░░ ░░░░░  ░░░░░░  ░░░░░ ░░░░░ ";

enum InputMode {
    Normal,
    Editing,
    ScrollingWords,
    ScrollingWordContent,
    AutomatedComms,
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
    dictionary_table_state: TableState,
    word_content_table_state: TableState,
    num_words: usize,
    current_selected_word_data_size: usize,
    automated_comms_string: String,
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
            dictionary_table_state: TableState::default(),
            word_content_table_state: TableState::default(),
            num_words: 0,
            current_selected_word_data_size: 0,
            automated_comms_string: String::new(),
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
                    " to start editing, ".into(),
                    "d".bold(),
                    " to scroll dictionary. ".into()
                ],
                Style::default().add_modifier(Modifier::RAPID_BLINK),
            ),
            InputMode::Editing => (
                vec![
                    "Press ".into(),
                    "Esc".bold(),
                    " to stop editing, ".into()
                ],
                Style::default(),
            ),
            InputMode::ScrollingWords => (
                vec![
                    "Press ".into(),
                    "Esc".bold(),
                    " to stop scrolling, ".into(),
                    "Press w to scroll words memory".into()
                ],
                Style::default()
            ),
            InputMode::ScrollingWordContent => (
                vec![
                   "Press ".into(),
                    "Esc".bold(),
                    " to stop scrolling, Press ".into(),
                    "d ".bold(),
                    "to scroll words".into()
                ],
                Style::default()
            ),
            InputMode::AutomatedComms => (
                vec![
                   "loading new word data".into()
                ],
                Style::default()
            )
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
                        KeyCode::Char('d') => {
                            if self.dictionary_table_state.selected() == None {
                                self.dictionary_table_state.select(Some(0));
                            }
                            self.input_mode = InputMode::ScrollingWords;
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
                    InputMode::ScrollingWords => match key.code {
                        KeyCode::Esc => self.input_mode = InputMode::Normal,
                        KeyCode::Char('q') => {
                            return true;
                        },
                        KeyCode::Char('w') => { 
                            if self.word_content_table_state.selected() == None {
                                self.word_content_table_state.select(Some(0));
                            }
                            self.input_mode = InputMode::ScrollingWordContent; 
                        },
                        KeyCode::Up => {
                            match self.dictionary_table_state.selected() {
                                Some(x) if x == 0 => {}
                                Some(x) => { self.dictionary_table_state.select(Some(x - 1)); }
                                _ => {}
                            }      
                            return false;
                        },
                        KeyCode::Down => {
                            match self.dictionary_table_state.selected() {
                                Some(i) if i >= self.num_words - 1 => {},
                                Some(x) => { self.dictionary_table_state.select(Some(x + 1)); }
                                _ => {}
                            }      
                            return false;
                        },
                        _ => {}
                    },
                    InputMode::ScrollingWordContent => match key.code {
                        KeyCode::Esc => self.input_mode = InputMode::Normal,
                        KeyCode::Char('q') => {
                            return true;
                        },
                        KeyCode::Char('d') => self.input_mode = InputMode::ScrollingWords,
                        KeyCode::Up => {
                            match self.word_content_table_state.selected() {
                                Some(x) if x == 0 => {}
                                Some(x) => { self.word_content_table_state.select(Some(x - 1)); }
                                _ => {}
                            }      
                            return false;
                        },
                        KeyCode::Down => {
                            match self.word_content_table_state.selected() {
                                Some(i) if i >= self.current_selected_word_data_size - 1 => {},
                                Some(x) => { self.word_content_table_state.select(Some(x + 1)); }
                                _ => {}
                            }      
                            return false;
                        },
                        _ => {}
                    }
                    _ => {}
                }
            }
        }
        false
    }
    
    fn read_serial(&mut self, mut port: &mut dyn serialport::SerialPort, forth_state: &mut ForthState) {
        match self.input_mode {
            InputMode::AutomatedComms => {
                let mut buf: [u8; 64000] = [0; 64000];
                match port.read(buf.as_mut_slice()) {
                    Ok(value) => {
                        for i in 0..value {
                            self.automated_comms_string.push(buf[i] as char);
                        }
                    }
                    Err(ref e) if e.kind() == std::io::ErrorKind::TimedOut => {
                        // no data available right now
                        let lines = self.automated_comms_string.lines().skip(1);
                        parse_showWords(lines, forth_state);
                        self.input_mode = InputMode::Editing;
                    }
                    Err(e) => {
                        self.next_state = DeviceConnectionState::EstablishingSerialPortConnection;
                    }
                }
            },
            _ => {
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
                                let last_line = self.input.lines().last();
                                match last_line {
                                    Some(x) => {
                                        if x.contains(";") {
                                            self.automated_comms_string = String::new();
                                            self.input_mode = InputMode::AutomatedComms;
                                            let cmd = "showLastWord\r";
                                            port.write(cmd.as_bytes());
                                        }
                                    }
                                    _ =>{}
                                };
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
        }
        
    }

    fn render(&mut self, frame: &mut Frame, forth_state: &ForthState) {
        let banner_height = banner.lines().count() as u16;
        let outer_chunks = Layout::default()
            .direction(Direction::Vertical)
            .constraints([
                Constraint::Length(banner_height),
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
            .split(outer_chunks[2]);
        
        let memory_data_bar = Layout::default()
                .direction(Direction::Vertical)
                .constraints([
                    Constraint::Percentage(50),
                    Constraint::Percentage(50),
                ])
                .split(inner_chunks[1]);

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

        let banner_text = Text::from(banner).style(Style::default().fg(Color::Green));
        let banner_p = Paragraph::new(banner_text);
        frame.render_widget(banner_p, outer_chunks[0]);

        let text = Text::from(Line::from(msg)).patch_style(style);
        let help_message = Paragraph::new(text);
        frame.render_widget(help_message, outer_chunks[1]);

        let input = Paragraph::new(self.input.as_str())
            .style(match self.input_mode {
                InputMode::Normal => Style::default(),
                InputMode::Editing => Style::default().fg(Color::Yellow),
                InputMode::ScrollingWords => Style::default(),
                InputMode::ScrollingWordContent=> Style::default(),
                InputMode::AutomatedComms => Style::default().fg(Color::Yellow),
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
            InputMode::ScrollingWords => {},
            InputMode::ScrollingWordContent => {},
            InputMode::AutomatedComms => {},
        }

        let mut rows: Vec<Row> = vec![];
        let mut row_keys: Vec<&str> = vec![];


        for (key, value) in forth_state.words.iter() {
            rows.push(Row::new(vec![key as &str, &value.address_string as &str]));
            row_keys.push(key as &str);
        }
        self.num_words = rows.len();
        let widths = [
            Constraint::Percentage(50),
            Constraint::Percentage(50),
        ];
        let words_table = Table::new(rows, widths)
            .block(Block::bordered().title("Words"))
            .style(match self.input_mode {
                InputMode::Normal => Style::default(),
                InputMode::Editing => Style::default(),
                InputMode::ScrollingWords => Style::default().fg(Color::Yellow),
                InputMode::ScrollingWordContent => Style::default(),
                InputMode::AutomatedComms => Style::default(),
            })
            .row_highlight_style(Style::new().reversed())
            .highlight_symbol(">>");

        frame.render_stateful_widget(words_table, memory_data_bar[0], &mut self.dictionary_table_state);


        let mut word_rows: Vec<Row>  = vec![];
        match self.dictionary_table_state.selected() {
            Some(x) => {
                let r = &forth_state.words[row_keys[x]].data;
                for d in r {
                    
                    word_rows.push(Row::new(vec![ d.address_str.as_str(), d.data_str.as_str(), d.annotation.as_str()]));
                }
            },
            None => {}
        };
        self.current_selected_word_data_size = word_rows.len();

        let selected_word_widths = [
            Constraint::Percentage(33),
            Constraint::Percentage(33),
            Constraint::Percentage(34),
        ];
        let word_content_table = Table::new(word_rows, selected_word_widths)
            .block(Block::bordered().title("Words"))
            .style(match self.input_mode {
                InputMode::Normal => Style::default(),
                InputMode::Editing => Style::default(),
                InputMode::ScrollingWords => Style::default(),
                InputMode::ScrollingWordContent => Style::default().fg(Color::Yellow),
                InputMode::AutomatedComms => Style::default(),
            })
            .row_highlight_style(Style::new().reversed())
            .highlight_symbol(">>");

        frame.render_stateful_widget(word_content_table, memory_data_bar[1], &mut self.word_content_table_state);

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