module suimo::item {
    use std::string::{Self, String, utf8};

    use sui::display;
    use sui::dynamic_object_field as dof;
    use sui::object::{Self, UID};
    use sui::package;
    use sui::table::{Self, Table};
    use sui::transfer::{public_transfer, share_object};
    use sui::tx_context::{TxContext, sender};
    use sui::url::{Self, Url};

    use suimo::utils::{Self, common_rarity_key, check_rarity, epic_rarity_key, rare_rarity_key, legendary_rarity_key, AdminCap};

    friend suimo::store;


    // ======== Constants =========
    const ITEM_NAME: vector<u8> = b"SuiMo Item";
    
    

    // ======== Error codes =========
    const EInvalidItemType: u64 = 0;
    

    // ======== Types =========
    struct ItemHub has key {
        id: UID,

        // dof item types
        // item_types: Table<u64, SuimoItemType>
    }

    struct Item has key, store {
        id: UID,
        // metadata
        name: String,
        description: String,
        url: Url,
        // stats
        xp: u64,
        ///
        type: String,
    }

    struct ItemType has store, drop {
        description: String,
        url: Url,
        xp: u64,
        ///  weapon, armor, accessory
        type: String,
    }

    struct ITEM has drop {}

    // ======== Events =========

    // ======== Functions =========

    fun init(otw: ITEM, ctx: &mut TxContext) {
        let publisher = package::claim(otw, ctx);

        // Item display
        let item_keys = vector[
            utf8(b"name"),
            utf8(b"description"),
            utf8(b"image_url"),
            utf8(b"project_url"),
        ];
        let item_values = vector[
            utf8(b"{name}"),
            utf8(b"{description}"),
            utf8(b"{url}"),
            utf8(b"https://www.suimo.com"),
        ];
        let item_display = display::new_with_fields<Item>(
            &publisher, item_keys, item_values, ctx
        );
        display::update_version(&mut item_display);

        let hub = ItemHub {
            id: object::new(ctx),
        };
        dof::add(&mut hub.id, common_rarity_key(), initialize_common_item_types(ctx));
        dof::add(&mut hub.id, rare_rarity_key(), initialize_rare_item_types(ctx));
        dof::add(&mut hub.id, epic_rarity_key(), initialize_epic_item_types(ctx));
        dof::add(&mut hub.id, legendary_rarity_key(), initialize_legendary_item_types(ctx));

        share_object(hub);
        public_transfer(item_display, sender(ctx));
        public_transfer(publisher, sender(ctx));
    }

    // ======= Admin functions =======

    public entry fun add_item_type(
        _: &AdminCap,
        hub: &mut ItemHub,
        rarity: String,
        description: String,
        url: String,
        type: String,
        xp: u64,
        _: &mut TxContext
    ) {
        check_type(type);
        let food_types = borrow_item_types_mut(hub, rarity);
        let index = table::length(food_types);
        table::add(food_types, index, ItemType {
            description,
            url: url::new_unsafe(string::to_ascii(url)),
            xp,
            type,
        });
    }

    public entry fun remove_item_type(
        _: &AdminCap,
        hub: &mut ItemHub,
        rarity: String,
        _: &mut TxContext
    ) {
        let item_types = borrow_item_types_mut(hub, rarity);
        let last_index = table::length(item_types) - 1;
        table::remove(item_types, last_index);
    }

    // ======= User functions =======

    // ======= Friend functions =======

    /**
        Mint a random item with a random rarity.
    */
    public(friend) fun create(hub: &ItemHub, ctx: &mut TxContext): Item {
        let rarity = utils::calclulate_rarity(ctx);
        let item_types = borrow_item_types(hub, rarity);
        let random = utils::rand_u64_from_zero_to(table::length(item_types), ctx);
        let rand_item_type = table::borrow(item_types, random);

        Item {
            id: object::new(ctx),
            name: utf8(ITEM_NAME),
            description: rand_item_type.description,
            url: rand_item_type.url,
            xp: rand_item_type.xp,
            type: rand_item_type.type,  
        }
    }

    // ======= View functions =======
    public fun weapon_type_key(): String {
        utf8(b"weapon")
    }

    public fun armor_type_key(): String {
        utf8(b"armor")
    }

    public fun accessory_type_key(): String {
        utf8(b"accessory")
    }

    public fun boots_type_key(): String {
        utf8(b"boots")
    }

    public fun hat_type_key(): String {
        utf8(b"hat")
    }

    public fun mystery_type_key(): String {
        utf8(b"mystery")
    }

    public fun xp(item: &Item): u64 {
        item.xp
    }

    public fun type(item: &Item): String {
        item.type
    }

    public fun borrow_item_types(hub: &ItemHub, rarity: String): &Table<u64, ItemType> {
        check_rarity(rarity);
        dof::borrow(&hub.id, rarity)
    }

    // ======= Utility functions =======

    public fun check_type(type: String) {
        assert!(
            type == weapon_type_key() || type == armor_type_key() || type == accessory_type_key() || type == boots_type_key() || type == hat_type_key() || type == mystery_type_key(),
            EInvalidItemType
        );
    }

    fun borrow_item_types_mut(hub: &mut ItemHub, rarity: String): &mut Table<u64, ItemType> {
        check_rarity(rarity);
        dof::borrow_mut(&mut hub.id, rarity)
    }

    fun initialize_common_item_types(ctx: &mut TxContext): Table<u64, ItemType> {
        let item_types = table::new<u64, ItemType>(ctx);
        table::add(&mut item_types, 0, ItemType {
            description: utf8(b"White cap"),
            url: url::new_unsafe_from_bytes(b"ipfs://QmVYMGnoRg6KPnQ3m5tugdgFG1ydvbJWL7XpP1DVf9Unvg/hat/white_cap.png"),
            xp: 1,
            type: hat_type_key(),
        });
        table::add(&mut item_types, 1, ItemType {
            description: utf8(b"Rags"),
            url: url::new_unsafe_from_bytes(b"ipfs://QmVYMGnoRg6KPnQ3m5tugdgFG1ydvbJWL7XpP1DVf9Unvg/pants/pandas_pants.png"),
            xp: 1,
            type: armor_type_key(),
        });
        table::add(&mut item_types, 2, ItemType {
            description: utf8(b"Umbrella"),
            url: url::new_unsafe_from_bytes(b"ipfs://QmVYMGnoRg6KPnQ3m5tugdgFG1ydvbJWL7XpP1DVf9Unvg/weapons/umbrella.png"),
            xp: 1,
            type: weapon_type_key(),
        });
        table::add(&mut item_types, 3, ItemType {
            description: utf8(b"Brown boots"),
            url: url::new_unsafe_from_bytes(b"ipfs://QmVYMGnoRg6KPnQ3m5tugdgFG1ydvbJWL7XpP1DVf9Unvg/boots/brown_boots.png"),
            xp: 1,
            type: boots_type_key(),
        });
        table::add(&mut item_types, 4, ItemType {
            description: utf8(b"Light earring"),
            url: url::new_unsafe_from_bytes(b"ipfs://QmVYMGnoRg6KPnQ3m5tugdgFG1ydvbJWL7XpP1DVf9Unvg/accessory/light_earring.png"),
            xp: 1,
            type: accessory_type_key(),
        });
        table::add(&mut item_types, 5, ItemType {
            description: utf8(b"Milk Cat"),
            url: url::new_unsafe_from_bytes(b"ipfs://QmVYMGnoRg6KPnQ3m5tugdgFG1ydvbJWL7XpP1DVf9Unvg/pets/cat.png"),
            xp: 1,
            type: mystery_type_key(),
        });

        item_types
    }

    fun initialize_rare_item_types(ctx: &mut TxContext): Table<u64, ItemType> {
        let item_types = table::new<u64, ItemType>(ctx);
        table::add(&mut item_types, 0, ItemType {
            description: utf8(b"Samurai hat"),
            url: url::new_unsafe_from_bytes(b"ipfs://QmVYMGnoRg6KPnQ3m5tugdgFG1ydvbJWL7XpP1DVf9Unvg/hat/samurai_hat.png"),
            xp: 2,
            type: hat_type_key(),
        });
        table::add(&mut item_types, 1, ItemType {
            description: utf8(b"Cabe mans skirt"),
            url: url::new_unsafe_from_bytes(b"ipfs://QmVYMGnoRg6KPnQ3m5tugdgFG1ydvbJWL7XpP1DVf9Unvg/pants/cave_man_skirt.png"),
            xp: 2,
            type: armor_type_key(),
        });
        table::add(&mut item_types, 2, ItemType {
            description: utf8(b"Guitar"),
            url: url::new_unsafe_from_bytes(b"ipfs://QmVYMGnoRg6KPnQ3m5tugdgFG1ydvbJWL7XpP1DVf9Unvg/weapons/guitar.png"),
            xp: 2,
            type: weapon_type_key(),
        });
        table::add(&mut item_types, 3, ItemType {
            description: utf8(b"Dr martens"),
            url: url::new_unsafe_from_bytes(b"ipfs://QmVYMGnoRg6KPnQ3m5tugdgFG1ydvbJWL7XpP1DVf9Unvg/boots/dr_martens.png"),
            xp: 2,
            type: boots_type_key(),
        });
        table::add(&mut item_types, 4, ItemType {
            description: utf8(b"Leaves"),
            url: url::new_unsafe_from_bytes(b"ipfs://QmVYMGnoRg6KPnQ3m5tugdgFG1ydvbJWL7XpP1DVf9Unvg/accessory/leaves.png"),
            xp: 2,
            type: accessory_type_key(),
        });
        table::add(&mut item_types, 5, ItemType {
            description: utf8(b"Alpine Husky"),
            url: url::new_unsafe_from_bytes(b"ipfs://QmVYMGnoRg6KPnQ3m5tugdgFG1ydvbJWL7XpP1DVf9Unvg/pets/dog.png"),
            xp: 2,
            type: mystery_type_key(),
        });

        item_types
    }

    fun initialize_epic_item_types(ctx: &mut TxContext): Table<u64, ItemType> {
        let item_types = table::new<u64, ItemType>(ctx);
        table::add(&mut item_types, 0, ItemType {
            description: utf8(b"Cowboy hat"),
            url: url::new_unsafe_from_bytes(b"ipfs://QmVYMGnoRg6KPnQ3m5tugdgFG1ydvbJWL7XpP1DVf9Unvg/hat/cowboy_hat.png"),
            xp: 3,
            type: hat_type_key(),
        });
        table::add(&mut item_types, 1, ItemType {
            description: utf8(b"American panties"),
            url: url::new_unsafe_from_bytes(b"ipfs://QmVYMGnoRg6KPnQ3m5tugdgFG1ydvbJWL7XpP1DVf9Unvg/pants/american_panties.png"),
            xp: 3,
            type: boots_type_key(),
        });
        table::add(&mut item_types, 2, ItemType {
            description: utf8(b"Sword"),
            url: url::new_unsafe_from_bytes(b"ipfs://QmVYMGnoRg6KPnQ3m5tugdgFG1ydvbJWL7XpP1DVf9Unvg/weapons/sword.png"),
            xp: 3,
            type: weapon_type_key(),
        });
        table::add(&mut item_types, 3, ItemType {
            description: utf8(b"Converse"),
            url: url::new_unsafe_from_bytes(b"ipfs://QmVYMGnoRg6KPnQ3m5tugdgFG1ydvbJWL7XpP1DVf9Unvg/boots/converse.png"),
            xp: 3,
            type: armor_type_key(),
        });
        table::add(&mut item_types, 4, ItemType {
            description: utf8(b"Star knife"),
            url: url::new_unsafe_from_bytes(b"ipfs://QmVYMGnoRg6KPnQ3m5tugdgFG1ydvbJWL7XpP1DVf9Unvg/accessory/star_knife.png"),
            xp: 3,
            type: accessory_type_key(),
        });
        table::add(&mut item_types, 5, ItemType {
            description: utf8(b"Monkey Chuy"),
            url: url::new_unsafe_from_bytes(b"ipfs://QmVYMGnoRg6KPnQ3m5tugdgFG1ydvbJWL7XpP1DVf9Unvg/pets/monkey.png"),
            xp: 3,
            type: mystery_type_key(),
        });
        item_types
    }

    fun initialize_legendary_item_types(ctx: &mut TxContext): Table<u64, ItemType> {
        let item_types = table::new<u64, ItemType>(ctx);
        table::add(&mut item_types, 0, ItemType {
            description: utf8(b"Macdonalds cap"),
            url: url::new_unsafe_from_bytes(b"ipfs://QmVYMGnoRg6KPnQ3m5tugdgFG1ydvbJWL7XpP1DVf9Unvg/hat/mcdonalds_cap.png"),
            xp: 5,
            type: hat_type_key(),
        });
        table::add(&mut item_types, 1, ItemType {
            description: utf8(b"Duck"),
            url: url::new_unsafe_from_bytes(b"ipfs://QmVYMGnoRg6KPnQ3m5tugdgFG1ydvbJWL7XpP1DVf9Unvg/pants/duck.png"),
            xp: 5,
            type: armor_type_key(),
        });
        table::add(&mut item_types, 2, ItemType {
            description: utf8(b"Glock"),
            url: url::new_unsafe_from_bytes(b"ipfs://QmVYMGnoRg6KPnQ3m5tugdgFG1ydvbJWL7XpP1DVf9Unvg/weapons/Guns.png"),
            xp: 5,
            type: weapon_type_key(),
        });
        table::add(&mut item_types, 3, ItemType {
            description: utf8(b"Hermes sandals"),
            url: url::new_unsafe_from_bytes(b"ipfs://QmVYMGnoRg6KPnQ3m5tugdgFG1ydvbJWL7XpP1DVf9Unvg/boots/hermes_sandals.png"),
            xp: 5,
            type: boots_type_key(),
        });
        table::add(&mut item_types, 4, ItemType {
            description: utf8(b"Yinyang amulet"),
            url: url::new_unsafe_from_bytes(b"ipfs://QmVYMGnoRg6KPnQ3m5tugdgFG1ydvbJWL7XpP1DVf9Unvg/accessory/yin_yang_necklace.png"),
            xp: 5,
            type: accessory_type_key(),
        });
        table::add(&mut item_types, 5, ItemType {
            description: utf8(b"Blue Whale"),
            url: url::new_unsafe_from_bytes(b"ipfs://QmVYMGnoRg6KPnQ3m5tugdgFG1ydvbJWL7XpP1DVf9Unvg/pets/whale.png"),
            xp: 5,
            type: mystery_type_key(),
        });
        item_types
    }
}