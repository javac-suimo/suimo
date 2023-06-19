module suimo::utils {
    use std::string::{utf8, String};
    use std::vector;

    use sui::bcs;
    use sui::hash;
    use sui::object::{Self, UID};
    use sui::transfer::transfer;
    use sui::tx_context::{Self, TxContext, sender};

    const EInvalidRarity: u64 = 0;

    /// AdminCap is a capability that allows the owner to perform administrative actions.
    struct AdminCap has key, store {
        id: UID,
    }

    /** Returns the admin capability once it is initialized. */
    fun init(ctx: &mut TxContext) {
        transfer(AdminCap { id: object::new(ctx) }, sender(ctx));
    }

    // ======= Rarity functions =======

    public fun check_rarity(rarity: String) {
        assert!(
            rarity == common_rarity_key() || rarity == epic_rarity_key() || rarity == legendary_rarity_key() || rarity == rare_rarity_key(),
            EInvalidRarity
        );
    }

    public fun calclulate_rarity(ctx: &mut TxContext): String {
        // TODO: increase rarity number form 100 to 10000 and change the rarity calculation
        let rarity = rand_u64_from_zero_to(100, ctx);
        if (rarity < 60) {
            common_rarity_key()
        } else if (rarity < 80){
            rare_rarity_key()
        } else if (rarity < 97) {
            epic_rarity_key()
        } else {
            legendary_rarity_key()
        }
    }


    public fun common_rarity_key(): String {
        utf8(b"common")
    }

    public fun rare_rarity_key(): String {
        utf8(b"rare")
    }

    public fun epic_rarity_key(): String {
        utf8(b"epic")
    }

    public fun legendary_rarity_key(): String {
        utf8(b"legendary")
    }

    // ======= Math functions =======

    /** Generates a random u64 in the range [0, range). */
    public fun rand_u64_from_zero_to(to: u64, ctx: &mut TxContext): u64 {
        rand_u64(ctx) % to
    }

    /** Generates a random u64 in the range [from, to]. */
    public fun rand_u64_in_range(from: u64, to: u64, ctx: &mut TxContext): u64 {
        rand_u64(ctx) % (to - from + 1) + from
    }

    public fun u64_to_string(value: u64): String {
        if (value == 0) {
            return utf8(b"0")
        };
        let buffer = vector::empty<u8>();
        while (value != 0) {
            vector::push_back(&mut buffer, ((48 + value % 10) as u8));
            value = value / 10;
        };
        vector::reverse(&mut buffer);
        utf8(buffer)
    }

    public fun get_value_percentage(value: u64, percentage: u64): u64 {
        value * percentage / 100
    }

    // ======= Utilities functions =======

    fun rand_u64(ctx: &mut TxContext): u64 {
        let nonce = vector::empty();
        vector::append(&mut nonce, nonce_primitives(ctx));
        bcs::peel_u64(&mut bcs::new(hash::keccak256(&nonce)))
    }

    fun nonce_primitives(ctx: &mut TxContext): vector<u8> {
        let uid = object::new(ctx);
        let object_nonce = object::uid_to_bytes(&uid);

        let epoch_nonce = bcs::to_bytes(&tx_context::epoch(ctx));
        vector::append(&mut object_nonce, epoch_nonce);

        let sender_nonce = bcs::to_bytes(&tx_context::sender(ctx));
        vector::append(&mut object_nonce, sender_nonce);

        object::delete(uid);
        object_nonce
    }
}