module suimo::store {
    use std::string::{String};

    use sui::balance::{Self, Balance};
    use sui::coin::{Self, Coin};

    use sui::event::emit;
    use sui::object::{Self, UID, ID};
    use sui::package;
    use sui::pay;
    use sui::sui::SUI;
    use sui::transfer::{public_transfer, share_object};
    use sui::tx_context::{TxContext, sender};

    use suimo::item::{Self, ItemHub};
    use suimo::suimo::{Self};
    use suimo::utils::{AdminCap};


    const MO_SUPPLY: u64 = 10000;
    
    // ======== Error codes =========
    const EInsufficientPay: u64 = 0;
    const EZeroBalance: u64 = 1;
    const EMaxSupply: u64 = 2;


    // ======== Types ==========
    struct STORE has drop {}

    struct StoreHub has key {
        id: UID,

        suimo_minted: u64,
        suimo_supply: u64,
        suimo_burned: u64,
        // suimo
        suimo_price: u64,
        // items
        item_price: u64,

        // balance
        balance: Balance<SUI>,
    }


    // ======== Events =========

    struct SuimoMinted has copy, drop {
        suimo_id: ID,
        minter: address,
    }

    struct SuimoItemMinted has copy, drop {
        item_id: ID,
        rarity: String,
        minter: address,
    }

    // ======== Functions =========

    fun init(otw: STORE, ctx: &mut TxContext) {
        let publisher = package::claim(otw, ctx);
        public_transfer(publisher, sender(ctx));

        share_object(StoreHub {
            id: object::new(ctx),
            suimo_minted: 0,
            suimo_supply:100000,
            suimo_price: 10000000,
            suimo_burned: 0,
            item_price: 10000000,
            balance: balance::zero(),
        });
    }

    // ======= Admin functions =======

    public entry fun withdraw(_: &AdminCap, store: &mut StoreHub, ctx: &mut TxContext) {
        let amount = balance::value(&store.balance);
        assert!(amount > 0, EZeroBalance);

        pay::keep(coin::take(&mut store.balance, amount, ctx), ctx);
    }

    public entry fun update_suimo_price(_: &AdminCap, store: &mut StoreHub, price: u64, _: &mut TxContext) {
        store.suimo_price = price;
    }
    public entry fun update_item_price(_: &AdminCap, store: &mut StoreHub, price: u64, _: &mut TxContext) {
        store.item_price = price;
    }
    public entry fun update_item_supply(_: &AdminCap, store: &mut StoreHub, supply: u64, _: &mut TxContext) {
        store.suimo_supply = supply;
    }

    // ======= User functions =======

    public entry fun mint_item(
        store: &mut StoreHub,
        i_hub: &mut ItemHub,
        coin: Coin<SUI>,
        ctx: &mut TxContext
    ) {
        let price = store.item_price;
        handle_payment(store, coin, price, ctx);
        handle_open_item(i_hub, ctx);
    }


    public entry fun mint_suimo(store: &mut StoreHub, coin: Coin<SUI>, ctx: &mut TxContext) {
        let new_minted = store.suimo_minted + 1;
        let total = store.suimo_supply;
        assert!(new_minted <= total, EMaxSupply);
        store.suimo_minted = new_minted;

        let price = store.suimo_price;
        handle_payment(store, coin, price, ctx);
        
        let suimo = suimo::create(new_minted, ctx);

        emit(SuimoMinted {
            suimo_id: object::id(&suimo),
            minter: sender(ctx),
        });

        public_transfer(suimo, sender(ctx));
    }

    public fun replenish_balance(store: &mut StoreHub, coin: Coin<SUI>) {
        coin::put(&mut store.balance, coin);
    }

    
    // ======= View functions =======
    public fun suimo_price(store: &StoreHub): u64 {
        store.suimo_price
    }

    public fun balance(store: &StoreHub): u64 {
        balance::value(&store.balance)
    }

    // ======= Utility functions =======
    fun handle_payment(store: &mut StoreHub, coin: Coin<SUI>, price: u64, ctx: &mut TxContext) {
        assert!(coin::value(&coin) >= price, EInsufficientPay);
        let payment = coin::split(&mut coin, price, ctx);
        replenish_balance(store, payment);
        pay::keep(coin, ctx);
    }

    fun handle_open_item(
        i_hub: &mut ItemHub,
        ctx: &mut TxContext
    ) {
        let i = 2;
        while (i < 3) {
            open_item(i_hub, ctx);
            i = i + 1;
        };
    }

    // Common Mystery Box:
    // Common Food: 75% chance
    // Common Clothing: 25% chance
    fun open_item(i_hub: &mut ItemHub, ctx: &mut TxContext) {
        let item = item::create(i_hub, ctx);
        public_transfer(item, sender(ctx));
        
    }

}
