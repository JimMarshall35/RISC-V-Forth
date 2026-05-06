use ratatui::{Frame};
use serialport::{SerialPort};

use crate::forth_state::ForthState;

#[derive(Clone, PartialEq, Eq)]

pub enum DeviceConnectionState {
    EstablishingSerialPortConnection,
    RequestingDeviceReset,
    InitialHandshake,
    Connected
}

pub trait DeviceConnectionStateImplementation {
    // first returned bool == was there any problem with serial writes, second bool, do we want to quit application
    fn handle_input(&mut self, port: &mut dyn SerialPort) -> bool;

    /// returned bool == was there a problem with serial reads
    fn read_serial(&mut self, port:&mut dyn SerialPort, forth_state: &mut ForthState);
    fn render(&mut self, frame: &mut Frame, forth_state: &ForthState);

    fn on_enter_state(&mut self, port: &mut dyn SerialPort, forth_state: &mut ForthState);

    fn on_exit_state(&mut self);

    // return the next state to transition to
    fn next_state(&mut self) -> DeviceConnectionState;
}
