use arcis::*;

#[encrypted]
mod circuits {
    use arcis::*;

    pub struct <INPUT_STRUCT_NAME> {
        pub <INPUT_FIELD_A>: u64,
        pub <INPUT_FIELD_B>: bool,
    }

    pub struct <OUTPUT_STRUCT_NAME> {
        pub <OUTPUT_FIELD_A>: u64,
        pub <OUTPUT_FIELD_B>: bool,
    }

    #[instruction]
    pub fn <IX_NAME>(
        // For Enc<Shared, T>, program/client must pass x25519 pubkey then nonce, then ciphertext fields.
        input_ctxt: Enc<Shared, <INPUT_STRUCT_NAME>>,
        // Include Mxe/Shared owners explicitly when output ownership differs.
        receiver: Shared,
    ) -> Enc<Shared, <OUTPUT_STRUCT_NAME>> {
        let input = input_ctxt.to_arcis();

        let output = <OUTPUT_STRUCT_NAME> {
            <OUTPUT_FIELD_A>: input.<INPUT_FIELD_A>,
            <OUTPUT_FIELD_B>: input.<INPUT_FIELD_B>,
        };

        receiver.from_arcis(output)
    }
}
