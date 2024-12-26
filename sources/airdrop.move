module Jrove::jairdrop {
    use std::signer;
    use aptos_framework::timestamp;
    use aptos_std::table;
    use aptos_std::table::Table;
    use Jrove::r_coin;

    #[test_only]
    use aptos_framework::primary_fungible_store;

    #[test_only]
    use aptos_framework::account;

    const ENOT_AUTHORIZED: u64 = 1;
    const ETOO_EARLY: u64 = 2;
    const AIRDROP_INTERVAL: u64 = 2 * 10; // 2 hours in seconds

    struct AirdropConfig has key {
        admin: address,
        amount_per_drop: u64,
        last_claim_time: Table<address, u64>,
    }

    public entry fun initialize(admin: &signer, amount_per_drop: u64) {
        let admin_addr = signer::address_of(admin);
        assert!(admin_addr == @Jrove, ENOT_AUTHORIZED);

        move_to(admin, AirdropConfig {
            admin: admin_addr,
            amount_per_drop,
            last_claim_time: table::new(),
        });
    }

    public entry fun claim_airdrop(admin: &signer, user_addr: address) acquires AirdropConfig{
        let admin_addr = signer::address_of(admin);
        let config = borrow_global_mut<AirdropConfig>(@Jrove);
        let current_time:u64 = timestamp::now_seconds();

        if (!table::contains(&config.last_claim_time, user_addr)) {
            table::add(&mut config.last_claim_time, user_addr, 0);
            
        };
        {
            let user_claim = table::borrow(&config.last_claim_time, user_addr);
            assert!(current_time >= *user_claim + AIRDROP_INTERVAL, ETOO_EARLY);
            r_coin::transfer(admin, admin_addr, user_addr, config.amount_per_drop);
            table::upsert(&mut config.last_claim_time, user_addr, current_time);
        };
    }

    public entry fun update_amount(admin: &signer, new_amount: u64) acquires AirdropConfig {
        let config = borrow_global_mut<AirdropConfig>(@Jrove);
        assert!(signer::address_of(admin) == config.admin, ENOT_AUTHORIZED);
        config.amount_per_drop = new_amount;
    }

    #[test(creator = @Jrove)]
}