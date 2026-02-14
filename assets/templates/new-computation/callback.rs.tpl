#[callback_accounts("<IX_NAME>")]
#[derive(Accounts)]
pub struct <CALLBACK_CONTEXT_NAME><'info> {
    pub arcium_program: Program<'info, Arcium>,
    #[account(address = derive_comp_def_pda!(COMP_DEF_OFFSET_<IX_NAME_UPPER>))]
    pub comp_def_account: Account<'info, ComputationDefinitionAccount>,
    #[account(address = derive_mxe_pda!())]
    pub mxe_account: Account<'info, MXEAccount>,
    /// CHECK: validated by arcium callback constraints
    pub computation_account: UncheckedAccount<'info>,
    #[account(address = derive_cluster_pda!(mxe_account, ErrorCode::ClusterNotSet))]
    pub cluster_account: Account<'info, Cluster>,
    #[account(address = ::anchor_lang::solana_program::sysvar::instructions::ID)]
    /// CHECK: validated by constraint
    pub instructions_sysvar: AccountInfo<'info>,
    #[account(mut)]
    pub <STATE_ACCOUNT>: Account<'info, <STATE_ACCOUNT_TYPE>>,
}

#[arcium_callback(encrypted_ix = "<IX_NAME>")]
pub fn <CALLBACK_FN_NAME>(
    ctx: Context<<CALLBACK_CONTEXT_NAME>>,
    output: SignedComputationOutputs<<OUTPUT_TYPE_NAME>>,
) -> Result<()> {
    let decoded = match output.verify_output(
        &ctx.accounts.cluster_account,
        &ctx.accounts.computation_account,
    ) {
        Ok(v) => v,
        Err(_) => return Err(ErrorCode::AbortedComputation.into()),
    };

    // Simple shape example:
    // let value = match decoded { <OUTPUT_TYPE_NAME> { field_0 } => field_0 };
    // Nested shape example:
    // let (a, b) = match decoded {
    //     <OUTPUT_TYPE_NAME> {
    //         field_0: <OUTPUT_STRUCT0_NAME> { field_0: a, field_1: b },
    //     } => (a, b),
    // };

    let encrypted_result = match decoded {
        <OUTPUT_TYPE_NAME> { field_0 } => field_0,
    };

    // Mandatory when indexing ciphertext arrays.
    require!(
        encrypted_result.ciphertexts.len() >= <MIN_CT_COUNT>,
        ErrorCode::<INVALID_CT_COUNT_ERROR>
    );

    let state = &mut ctx.accounts.<STATE_ACCOUNT>;
    state.<STATE_NONCE_FIELD> = encrypted_result.nonce;
    state.<STATE_CT_FIELD_0> = encrypted_result.ciphertexts[0];

    // Optional event emission.
    // emit!(<EVENT_NAME> { ... });

    Ok(())
}
