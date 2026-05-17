use crate::forth_state::{ForthState, ForthWord, MCUMemoryDataWord};

pub fn parse_showWords<'a>(lines: impl Iterator<Item = &'a str>, forth_state: &mut ForthState) {
    let mut word_under_construction: Option<ForthWord> = None;
    for line in lines {
        let tokens: Vec<&str> = line.trim().split_whitespace().collect();
        
        match tokens.len() {
            2 => {
                //word_under_construction.unwrap().data.push(MCUMemoryDataWord::from_tokens(&tokens));
                match &mut word_under_construction {
                    Some(x) => {
                        x.data.push(MCUMemoryDataWord::from_tokens(&tokens));
                    },
                    _ => {
                        panic!("no word under construction - serial output bad");
                    }
                }
            },
            4 => {
                match word_under_construction {
                    Some(x) => {
                        forth_state.words.push(x.clone());
                        word_under_construction = Some(ForthWord::from_tokens(&tokens))
                    },
                    None => {
                        word_under_construction = Some(ForthWord::from_tokens(&tokens));
                    }
                };
            }
            _ => {
                panic!("bad number of tokens - forth bad!");
            }
        };
    }
    match word_under_construction {
        Some(x) => {
            forth_state.words.push(x.clone());
        },
        None => {
        }
    };
    forth_state.annotate_data();
}