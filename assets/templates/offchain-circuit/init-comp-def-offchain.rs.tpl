use arcium_client::idl::arcium::types::{CircuitSource, OffChainCircuitSource};
use arcium_macros::circuit_hash;

pub fn init_<IX_NAME>_comp_def(ctx: Context<Init<IX_PASCAL>CompDef>) -> Result<()> {
    init_comp_def(
        ctx.accounts,
        Some(CircuitSource::OffChain(OffChainCircuitSource {
            // Keep this URL versioned/immutable for reproducible deployments.
            source: "<OFFCHAIN_CIRCUIT_URL>".to_string(),
            // Must match encrypted instruction name exactly.
            hash: circuit_hash!("<IX_NAME>"),
        })),
        None,
    )?;
    Ok(())
}
