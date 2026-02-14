#[derive(Accounts)]
#[instruction(<MATCHER_ARG>: Pubkey)]
pub struct SetPermission<'info> {
    #[account(mut)]
    pub payer: Signer<'info>,
    #[account(
        init_if_needed,
        payer = payer,
        space = 8 + <PERMISSION_ACCOUNT_TYPE>::INIT_SPACE,
        seeds = [b"<PERMISSION_SEED>", payer.key().as_ref(), <MATCHER_ARG>.as_ref()],
        bump,
    )]
    pub permission: Account<'info, <PERMISSION_ACCOUNT_TYPE>>,
    pub system_program: Program<'info, System>,
}

#[queue_computation_accounts("<IX_NAME>", payer)]
#[derive(Accounts)]
#[instruction(computation_offset: u64, <TARGET_OWNER_ARG>: Pubkey)]
pub struct <QUEUE_CONTEXT_NAME><'info> {
    #[account(mut)]
    pub payer: Signer<'info>,

    #[account(
        constraint = <REQUESTER_STATE_ACCOUNT>.<OWNER_FIELD> == payer.key()
            @ ErrorCode::<INVALID_OWNER_ERROR>,
    )]
    pub <REQUESTER_STATE_ACCOUNT>: Account<'info, <REQUESTER_STATE_ACCOUNT_TYPE>>,

    #[account(
        constraint = <TARGET_STATE_ACCOUNT>.<OWNER_FIELD> == <TARGET_OWNER_ARG>
            @ ErrorCode::<INVALID_OWNER_ERROR>,
    )]
    pub <TARGET_STATE_ACCOUNT>: Account<'info, <TARGET_STATE_ACCOUNT_TYPE>>,

    #[account(
        seeds = [b"<PERMISSION_SEED>", <TARGET_OWNER_ARG>.as_ref(), payer.key().as_ref()],
        bump = <PERMISSION_ACCOUNT>.bump,
        constraint = <PERMISSION_ACCOUNT>.allowed @ ErrorCode::<PERMISSION_DENIED_ERROR>,
    )]
    pub <PERMISSION_ACCOUNT>: Account<'info, <PERMISSION_ACCOUNT_TYPE>>,

    #[account(
        init,
        payer = payer,
        space = 8 + <JOB_ACCOUNT_TYPE>::INIT_SPACE,
        seeds = [
            b"<JOB_SEED>",
            payer.key().as_ref(),
            computation_offset.to_le_bytes().as_ref(),
        ],
        bump,
    )]
    pub <JOB_ACCOUNT>: Account<'info, <JOB_ACCOUNT_TYPE>>,

    // Include standard Arcium queue accounts below this line.
    #[account(
        init_if_needed,
        space = 9,
        payer = payer,
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
