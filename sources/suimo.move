module suimo::suimo {
    use std::option::{Self, Option};
    use std::string::{Self, String, utf8};

    use sui::display;
    use sui::object::{Self, UID};
    use sui::package;
    use sui::transfer::{public_transfer, share_object};
    use sui::tx_context::{TxContext, sender};
    use sui::url::{Self, Url};

    use suimo::item::{Self, Item, weapon_type_key, armor_type_key, accessory_type_key, boots_type_key, hat_type_key, check_type};
    use suimo::utils::{Self, u64_to_string, check_rarity, common_rarity_key, epic_rarity_key, rare_rarity_key, legendary_rarity_key};

    friend suimo::store;
    

    // ======== Constants =========

    /// Suimo
    const SUIMO_NAME: vector<u8> = b"SuiMO #";
    const IMAGE_URL: vector<u8> = b"https://app.suimo.xyz/image";
    const METADATA_URL: vector<u8> = b"https://app.suimo.xyz/metadata";
    
    const MOCKUP_IMAGE_URL_COMMON: vector<u8> = b"ipfs://Qmb5zBNnWxFRw7Y133fZ4YSMiEB56kwtfxsYsTA8zcfkF3/common.png";
    const MOCKUP_IMAGE_URL_RARE: vector<u8> = b"ipfs://Qmb5zBNnWxFRw7Y133fZ4YSMiEB56kwtfxsYsTA8zcfkF3/rare.png";
    const MOCKUP_IMAGE_URL_EPIC: vector<u8> = b"ipfs://Qmb5zBNnWxFRw7Y133fZ4YSMiEB56kwtfxsYsTA8zcfkF3/epic.png";
    const MOCKUP_IMAGE_URL_LEGENDARY: vector<u8> = b"ipfs://Qmb5zBNnWxFRw7Y133fZ4YSMiEB56kwtfxsYsTA8zcfkF3/legendary.png";
   
    const MOCKUP_FOLDER_IPFS: vector<u8> = b"ipfs://QmaoxQVVxUPjN6rGwjn7cBmmV4F9PvNdh7GSXVAZfmtGkC/";

   
    const INITIAL_LVL: u64 = 1;
    const MAX_LVL: u64 = 30;
    // ======== Error codes =========

    const EInvalidTripItems: u64 = 0;
    const ENoEquippedItems: u64 = 1;
    const ENoEquailSuimo: u64 = 2;
    const EInvalidLvl: u64 = 3;

    // ======== Types =========

    struct SuimoHub has key {
        id: UID,
    }

    struct Suimo has key, store {
        id: UID,
        // metadata
        name: String,
        rarity: String,
        url: Url,
        link: Url,
        // stats
        lvl: u64,

        health: u64,
        strength: u64,
        dexterity: u64,
        intellect: u64,
        stamina: u64,
        protection: u64,
        
        // items
        hat: Option<Item>,
        weapon: Option<Item>,
        armor: Option<Item>,
        accessory: Option<Item>,
        boots: Option<Item>,
        mystery: Option<Item>,
    }

    /// OTW
    struct SUIMO has drop {}

    // ======== Events =========


    // ======== Functions =========

    fun init(otw: SUIMO, ctx: &mut TxContext) {
        let publisher = package::claim(otw, ctx);

        // NFT display
        let nft_keys = vector[
            utf8(b"name"),
            utf8(b"image_url"),
            utf8(b"link"),
            utf8(b"project_url"),
        ];
        let nft_values = vector[
            utf8(b"{name}"),
            utf8(b"{url}"),
            utf8(b"{link}"),
            utf8(b"https://suimo.xyz/"),
        ];
        let nft_display = display::new_with_fields<Suimo>(
            &publisher, nft_keys, nft_values, ctx
        );
        display::update_version(&mut nft_display);

        let hub = SuimoHub {
            id: object::new(ctx),
        };

        public_transfer(nft_display, sender(ctx));
        public_transfer(publisher, sender(ctx));
        share_object(hub);
    }

    // ======= Admin functions =======

    // ======= User functions =======

    public entry fun equip_item(
        suimo: &mut Suimo,
        item: Item,
        _: &mut TxContext
    ) {
        let item_type = item::type(&item);
        check_type(item_type);
        let item_xp = item::xp(&item);

        if (item_type == weapon_type_key()) {
            option::fill(&mut suimo.weapon, item);
            suimo.health = suimo.health + item_xp;
        } else if (item_type == armor_type_key()) {
            option::fill(&mut suimo.armor, item);
            suimo.strength = suimo.strength + item_xp;
        } else if (item_type == accessory_type_key()) {
            option::fill(&mut suimo.accessory, item);
            suimo.dexterity = suimo.dexterity + item_xp;
        } else if(item_type == boots_type_key()) {
            option::fill(&mut suimo.boots, item);
            suimo.intellect =  suimo.intellect + item_xp;
        } else if(item_type == hat_type_key()){
            option::fill(&mut suimo.hat, item);
            suimo.stamina = suimo.stamina + item_xp;
        } else {
            option::fill(&mut suimo.mystery, item);
            suimo.protection = suimo.protection + item_xp;
        };
    }

    public entry fun remove_item(
        suimo: &mut Suimo,
        item_type: String,
        ctx: &mut TxContext
    ) {
        check_type(item_type);

        let item: Item;
        if (item_type == weapon_type_key()) {
            item = option::extract(&mut suimo.weapon);
            let item_xp = item::xp(&item);
            suimo.health = suimo.health - item_xp;
        } else if (item_type == armor_type_key()) {
            item = option::extract(&mut suimo.armor);
            let item_xp = item::xp(&item);
            suimo.strength = suimo.strength - item_xp;
        } else if(item_type == accessory_type_key()) {
            item = option::extract(&mut suimo.accessory);
            let item_xp = item::xp(&item);
            suimo.dexterity = suimo.dexterity - item_xp;
        } else if(item_type == boots_type_key()) {
            item = option::extract(&mut suimo.boots);
            let item_xp = item::xp(&item);
            suimo.intellect = suimo.intellect - item_xp;
        } else if(item_type == hat_type_key()){
             item = option::extract(&mut suimo.hat);
            let item_xp = item::xp(&item);
            suimo.stamina = suimo.stamina -  item_xp;
        } else {
            item = option::extract(&mut suimo.mystery);
            let item_xp = item::xp(&item);
            suimo.protection = suimo.protection - item_xp;
        };
        public_transfer(item, sender(ctx));
    }

    public entry fun merge(suimo_alive: &mut Suimo, suimo_dead: Suimo) { //, store: &mut StoreHub
        
        // suimo_alive and suimo_dead are not the same
        assert!(&suimo_alive.id != &suimo_dead.id, ENoEquailSuimo);
        // check max level
        let new_lvl = suimo_alive.lvl + 1;
        assert!(new_lvl <= MAX_LVL, EInvalidLvl);
        
        // merge stats
        suimo_alive.health = suimo_alive.health + suimo_dead.health;
        suimo_alive.strength = suimo_alive.strength + suimo_dead.strength;
        suimo_alive.dexterity = suimo_alive.dexterity + suimo_dead.dexterity;
        suimo_alive.intellect = suimo_alive.intellect + suimo_dead.intellect;
        suimo_alive.stamina = suimo_alive.stamina + suimo_dead.stamina;
        suimo_alive.protection = suimo_alive.protection + suimo_dead.protection;
        
         store.suimo_burned = store.suimo_burned + 1;
        delete(suimo_dead);
    }

    // ======= Friend functions =======

    public(friend) fun create(count: u64, ctx: &mut TxContext): Suimo {
        let id = object::new(ctx);
        let rarity = utils::calclulate_rarity(ctx);
        let image_url_testnet = based_on_rariry_get_image(rarity);
        // TODO: Change ipfs folder
        let image_url_ifps = image_url(count);
        Suimo {
            id,
            // metadata
            name: name_count(count),
            rarity: rarity,
            url: image_url_testnet,
            link: image_url_ifps,
            // stats
            lvl: INITIAL_LVL,
            health: based_on_rariry_get_stats(rarity, ctx),
            strength: based_on_rariry_get_stats(rarity, ctx),
            dexterity: based_on_rariry_get_stats(rarity, ctx),
            intellect: based_on_rariry_get_stats(rarity, ctx),
            stamina: based_on_rariry_get_stats(rarity, ctx),
            protection: based_on_rariry_get_stats(rarity, ctx),
            // items
            weapon: option::none(),
            armor: option::none(),
            accessory: option::none(),
            boots: option::none(),
            hat: option::none(),
            mystery: option::none(),
        }
    }

    
    // ======= Utility functions =======
    fun delete(suimo: Suimo) {
        let Suimo {
            id,
            // metadata
            name: _,
            url: _,
            link: _,
            lvl: _,
            health: _,
            strength: _,
            dexterity: _,
            intellect: _,
            rarity: _,
            stamina: _,
            protection: _,
            weapon,
            armor,
            accessory,
            boots,
            hat,
            mystery,
        } = suimo;
        assert!(option::is_none(&weapon) &&
            option::is_none(&armor) &&
            option::is_none(&accessory) &&
            option::is_none(&boots) &&
            option::is_none(&hat) &&
            option::is_none(&mystery),
            ENoEquippedItems
        );
        option::destroy_none(weapon);
        option::destroy_none(armor);
        option::destroy_none(accessory);
        option::destroy_none(boots);
        option::destroy_none(hat);
        option::destroy_none(mystery);
        object::delete(id);
    }

    fun name_count(ordinal_number: u64): String {
        let name = utf8(SUIMO_NAME);
        string::append(&mut name, u64_to_string(ordinal_number));
        name
    }

    fun image_url(ordinal_number: u64): Url {
        let image_url = utf8(MOCKUP_FOLDER_IPFS);
        string::append(&mut image_url, u64_to_string(ordinal_number));
        url::new_unsafe(string::to_ascii(image_url))
    }

    fun link_url(ordinal_number: u64): Url {
        let metadata_url = utf8(METADATA_URL);
        string::append(&mut metadata_url, u64_to_string(ordinal_number));
        url::new_unsafe(string::to_ascii(metadata_url))
    }

    fun based_on_rariry_get_image(rarity: String): Url {
        check_rarity(rarity);
        if(rarity == common_rarity_key()){
            url::new_unsafe_from_bytes(MOCKUP_IMAGE_URL_COMMON)
        } else if(rarity == rare_rarity_key()){
            url::new_unsafe_from_bytes(MOCKUP_IMAGE_URL_RARE)
        } else if(rarity == epic_rarity_key()){
            url::new_unsafe_from_bytes(MOCKUP_IMAGE_URL_EPIC)
        } else if(rarity == legendary_rarity_key()){
            url::new_unsafe_from_bytes(MOCKUP_IMAGE_URL_LEGENDARY)
        } else {
            url::new_unsafe_from_bytes(MOCKUP_IMAGE_URL_COMMON)
        }
    }

    fun based_on_rariry_get_stats(rarity: String, ctx: &mut TxContext): u64 {
        if(rarity == common_rarity_key()){
            utils::rand_u64_in_range(1, 3, ctx)
        } else if (rarity == rare_rarity_key()){
            utils::rand_u64_in_range(2, 4, ctx)
        } else if (rarity == epic_rarity_key()){
            utils::rand_u64_in_range(3, 5, ctx)
        } else if (rarity == legendary_rarity_key()){
            utils::rand_u64_in_range(4, 6, ctx)
        } else {
            utils::rand_u64_in_range(1, 3, ctx)   
        }
    }

    #[test_only]
    public fun init_test(ctx: &mut TxContext) {
        init(SUIMO {}, ctx)
    }

}