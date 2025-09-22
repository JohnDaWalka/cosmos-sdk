//! Cosmos-Polkadot compatibility node main entry point

use clap::Parser;
use futures::prelude::*;
use sc_cli::{ChainSpec, Result, SubstrateCli};
use sc_service::PartialComponents;

mod chain_spec;
mod cli;
mod command;
mod rpc;
mod service;

fn main() -> Result<()> {
    command::run()
}