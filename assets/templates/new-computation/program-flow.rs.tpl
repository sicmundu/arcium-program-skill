use anchor_lang::prelude::*;
use arcium_anchor::prelude::*;
use arcium_client::idl::arcium::types::CallbackAccount;

const COMP_DEF_OFFSET_<IX_NAME_UPPER>: u32 = comp_def_offset("<IX_NAME>");

declare_id!("<PROGRAM_ID>");

#[arcium_program]
pub mod <PROGRAM_MODULE_NAME> {
    use super::*;

    pub fn <QUEUE_IX_NAME>(
        ctx: Context<<QUEUE_CONTEXT_NAME>>,
        computation_offset: u64,
        <CLIENT_PUBKEY_ARG>: [u8; 32],
        <CLIENT_NONCE_ARG>: u128,
        <INPUT_CT_0_ARG>: [u8; 32],
        <STATE_NONCE_ARG>: u128,
    ) -> Result<()> {
        // Optional pre-queue guards (permission/state machine checks)
        // require!(..., ErrorCode::<ERR_NAME>);

        let args = ArgBuilder::new()
            // Enc<Shared, T> contract: x25519_pubkey -> nonce -> encrypted fields in circuit order.
            .x25519_pubkey(<CLIENT_PUBKEY_ARG>)
            .plaintext_u128(<CLIENT_NONCE_ARG>)
            .encrypted_u64(<INPUT_CT_0_ARG>)
            // Existing account-backed encrypted state (if applicable)
            .plaintext_u128(<STATE_NONCE_ARG>)
            .account(
                ctx.accounts.<STATE_ACCOUNT>.key(),
                <STATE_OFFSET>, // 8 + ... (document every preceding field byte)
                <STATE_LEN>,    // ciphertext_count * 32
            )
            .build();

        ctx.accounts.sign_pda_account.bump = ctx.bumps.sign_pda_account;

        queue_computation(
            ctx.accounts,
            computation_offset,
            args,
            vec![<CALLBACK_CONTEXT_NAME>::callback_ix(
                computation_offset,
                &ctx.accounts.mxe_account,
                &[CallbackAccount {
                    pubkey: ctx.accounts.<STATE_ACCOUNT>.key(),
                    is_writable: true,
                }],
            )?],
            1,
            0,
        )?;

        Ok(())
    }
}

#[queue_computation_accounts("<IX_NAME>", <PAYER_ACCOUNT_NAME>)]
#[derive(Accounts)]
#[instruction(computation_offset: u64)]
pub struct <QUEUE_CONTEXT_NAME><'info> {
    #[account(mut)]
    pub <PAYER_ACCOUNT_NAME>: Signer<'info>,
    #[account(mut)]
    pub <STATE_ACCOUNT>: Account<'info, <STATE_ACCOUNT_TYPE>>,
    #[account(
        init_if_needed,
        space = 9,
        payer = <PAYER_ACCOUNT_NAME>,
        seeds = [&SIGN_PDA_SEED],
        bump,
        address = derive_sign_pda!(),
    )]
    pub sign_pda_account: Account<'info, ArciumSignerAccount>,
    #[account(address = derive_mxe_pda!())]
    pub mxe_account: Account<'info, MXEAccount>,
    #[account(mut, address = derive_mempool_pda!(mxe_account, ErrorCode::ClusterNotSet))]
    /// CHECK: validated by arcium program
    pub mempool_account: UncheckedAccount<'info>,
    #[account(mut, address = derive_execpool_pda!(mxe_account, ErrorCode::ClusterNotSet))]
    /// CHECK: validated by arcium program
    pub executing_pool: UncheckedAccount<'info>,
    #[account(mut, address = derive_comp_pda!(computation_offset, mxe_account, ErrorCode::ClusterNotSet))]
    /// CHECK: validated by arcium program
    pub computation_account: UncheckedAccount<'info>,
    #[account(address = derive_comp_def_pda!(COMP_DEF_OFFSET_<IX_NAME_UPPER>))]
    pub comp_def_account: Account<'info, ComputationDefinitionAccount>,
    #[account(mut, address = derive_cluster_pda!(mxe_account, ErrorCode::ClusterNotSet))]
    pub cluster_account: Account<'info, Cluster>,
    #[account(mut, address = ARCIUM_FEE_POOL_ACCOUNT_ADDRESS)]
    pub pool_account: Account<'info, FeePool>,
    #[account(mut, address = ARCIUM_CLOCK_ACCOUNT_ADDRESS)]
    pub clock_account: Account<'info, ClockAccount>,
    pub system_program: Program<'info, System>,
    pub arcium_program: Program<'info, Arcium>,
}
