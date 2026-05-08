use std::collections::{HashMap};

use clap::builder::Str;
use serialport::new;

const HEADER_SIZE: u32 = 44;

#[derive(Clone)]
pub struct MCUMemoryDataWord {
    pub address: u32,
    pub data: u32,
    pub address_str: String,
    pub data_str: String,
    pub annotation: String,
}

impl MCUMemoryDataWord {
    pub fn from_tokens(tokens: &Vec<&str>) -> Self {
        let t0 = tokens[0];
        let t = tokens[1];
        let addr = u32::from_str_radix(t0.trim_start_matches("0x"), 16).unwrap();
        let val = u32::from_str_radix(t.trim_start_matches("0x"), 16).unwrap();
        Self { 
            address: addr, 
            data: val,
            address_str: format!("{:#010x}", addr),
            data_str: format!("{:#010x}", val),
            annotation: String::new(),
        }
    }
}

#[derive(Clone)]
pub struct ForthWord {
    pub name: String,
    pub address: u32,
    pub address_string: String,
    pub data: Vec<MCUMemoryDataWord>,
    pub is_primitive: bool,
    pub is_immediate: bool,
    
    pub impl_address: u32,
}

impl ForthWord {
    pub fn from_tokens(tokens: &Vec<&str>) -> Self {
        assert!(tokens.len() == 4);
        let address: u32 = u32::from_str_radix(tokens[0].trim_start_matches("0x"), 16).unwrap();
        let is_immediate: bool = u32::from_str_radix(tokens[2].trim_start_matches("0x"), 16).unwrap() != 0;
        let is_primititive: bool = u32::from_str_radix(tokens[3].trim_start_matches("0x"), 16).unwrap() != 0;
        Self {
            name: tokens[1].to_string(),
            address: address,
            address_string: format!("{:#010x}", address),
            data: vec![],
            is_immediate: is_immediate,
            is_primitive: is_primititive,
            impl_address: address + HEADER_SIZE
        }
    }
}

pub struct ForthState {
    pub words: HashMap<String, ForthWord>
}

impl ForthState {
    pub fn new() -> Self {
        Self {
            words: HashMap::new()
        }
    }
    pub fn lookup_word_impl_address(&self, address: u32) -> Option<String> {
        for (key, value) in self.words.iter() {
            if value.impl_address == address {
                return Some(format!("{}_impl", key));
            }
        }
        None
    }
    pub fn annotate_data(&mut self) {
        let address_map: HashMap<u32, String> = self.words
            .iter()
            .map(|(key, value)| {
                (value.impl_address, format!("{}_impl", key))
            })
            .collect();

        for value in self.words.values_mut() {
        for w in &mut value.data {
            if let Some(annotation) = address_map.get(&w.data) {
                w.annotation = annotation.clone();
            }
        }
    }
    }
}
