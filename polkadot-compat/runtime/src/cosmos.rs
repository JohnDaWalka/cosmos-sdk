//! Cosmos SDK bridge pallet
//! 
//! This pallet provides functionality to bridge between Cosmos SDK and Polkadot ecosystem.

#![cfg_attr(not(feature = "std"), no_std)]

use frame_support::{
    codec::{Decode, Encode},
    dispatch::{DispatchResult, DispatchError},
    traits::{Currency, Get},
    sp_runtime::traits::{Zero, Saturating},
};
use frame_system::ensure_signed;
use sp_std::vec::Vec;

pub use pallet::*;

#[frame_support::pallet]
pub mod pallet {
    use super::*;
    use frame_support::pallet_prelude::*;
    use frame_system::pallet_prelude::*;

    /// Configure the pallet by specifying the parameters and types on which it depends.
    #[pallet::config]
    pub trait Config: frame_system::Config {
        /// Because this pallet emits events, it depends on the runtime's definition of an event.
        type RuntimeEvent: From<Event<Self>> + IsType<<Self as frame_system::Config>::RuntimeEvent>;

        /// The currency used for transferring funds.
        type Currency: Currency<Self::AccountId>;

        /// Weight information for extrinsics in this pallet.
        type WeightInfo: WeightInfo;
    }

    #[pallet::pallet]
    #[pallet::generate_store(pub(super) trait Store)]
    pub struct Pallet<T>(_);

    /// The current cosmos chain ID that this bridge connects to.
    #[pallet::storage]
    #[pallet::getter(fn cosmos_chain_id)]
    pub type CosmosChainId<T> = StorageValue<_, Vec<u8>, ValueQuery>;

    /// Mapping from cosmos addresses to substrate accounts.
    #[pallet::storage]
    #[pallet::getter(fn cosmos_accounts)]
    pub type CosmosAccounts<T: Config> = StorageMap<
        _,
        Blake2_128Concat,
        Vec<u8>, // Cosmos address
        T::AccountId, // Substrate account
        OptionQuery,
    >;

    /// Cross-chain transaction records.
    #[pallet::storage]
    #[pallet::getter(fn cross_chain_transactions)]
    pub type CrossChainTransactions<T: Config> = StorageMap<
        _,
        Blake2_128Concat,
        T::Hash, // Transaction hash
        CrossChainTx<T::AccountId>,
        OptionQuery,
    >;

    #[pallet::event]
    #[pallet::generate_deposit(pub(super) fn deposit_event)]
    pub enum Event<T: Config> {
        /// A cosmos account was linked to a substrate account.
        CosmosAccountLinked {
            cosmos_address: Vec<u8>,
            substrate_account: T::AccountId,
        },
        /// Cross-chain transaction initiated.
        CrossChainTransactionInitiated {
            from: T::AccountId,
            to_cosmos_address: Vec<u8>,
            amount: T::Currency::Balance,
            tx_hash: T::Hash,
        },
        /// Cross-chain transaction completed.
        CrossChainTransactionCompleted {
            tx_hash: T::Hash,
        },
    }

    #[pallet::error]
    pub enum Error<T> {
        /// Account already linked to a cosmos address.
        AccountAlreadyLinked,
        /// Invalid cosmos address format.
        InvalidCosmosAddress,
        /// Cross-chain transaction not found.
        TransactionNotFound,
        /// Insufficient balance for cross-chain transfer.
        InsufficientBalance,
    }

    /// Cross-chain transaction structure
    #[derive(Encode, Decode, Clone, PartialEq, Eq, RuntimeDebug, TypeInfo)]
    pub struct CrossChainTx<AccountId> {
        pub from: AccountId,
        pub to_cosmos_address: Vec<u8>,
        pub amount: u128,
        pub status: TxStatus,
    }

    #[derive(Encode, Decode, Clone, PartialEq, Eq, RuntimeDebug, TypeInfo)]
    pub enum TxStatus {
        Initiated,
        Completed,
        Failed,
    }

    #[pallet::call]
    impl<T: Config> Pallet<T> {
        /// Link a substrate account to a cosmos address.
        #[pallet::weight(T::WeightInfo::link_cosmos_account())]
        #[pallet::call_index(0)]
        pub fn link_cosmos_account(
            origin: OriginFor<T>,
            cosmos_address: Vec<u8>,
        ) -> DispatchResult {
            let who = ensure_signed(origin)?;

            // Validate cosmos address format (basic validation)
            ensure!(
                cosmos_address.len() >= 20 && cosmos_address.len() <= 255,
                Error::<T>::InvalidCosmosAddress
            );

            // Check if account is already linked
            ensure!(
                !CosmosAccounts::<T>::contains_key(&cosmos_address),
                Error::<T>::AccountAlreadyLinked
            );

            // Store the link
            CosmosAccounts::<T>::insert(&cosmos_address, &who);

            // Emit event
            Self::deposit_event(Event::CosmosAccountLinked {
                cosmos_address,
                substrate_account: who,
            });

            Ok(())
        }

        /// Initiate a cross-chain transaction to Cosmos.
        #[pallet::weight(T::WeightInfo::initiate_cross_chain_tx())]
        #[pallet::call_index(1)]
        pub fn initiate_cross_chain_tx(
            origin: OriginFor<T>,
            to_cosmos_address: Vec<u8>,
            amount: T::Currency::Balance,
        ) -> DispatchResult {
            let who = ensure_signed(origin)?;

            // Check balance
            ensure!(
                T::Currency::free_balance(&who) >= amount,
                Error::<T>::InsufficientBalance
            );

            // Generate transaction hash
            let tx_hash = T::Hashing::hash_of(&(&who, &to_cosmos_address, &amount));

            // Create cross-chain transaction record
            let cross_chain_tx = CrossChainTx {
                from: who.clone(),
                to_cosmos_address: to_cosmos_address.clone(),
                amount: amount.saturated_into::<u128>(),
                status: TxStatus::Initiated,
            };

            // Store transaction
            CrossChainTransactions::<T>::insert(&tx_hash, &cross_chain_tx);

            // Reserve the amount (in real implementation, this would be burned or locked)
            T::Currency::reserve(&who, amount)?;

            // Emit event
            Self::deposit_event(Event::CrossChainTransactionInitiated {
                from: who,
                to_cosmos_address,
                amount,
                tx_hash,
            });

            Ok(())
        }

        /// Complete a cross-chain transaction (called by relayer).
        #[pallet::weight(T::WeightInfo::complete_cross_chain_tx())]
        #[pallet::call_index(2)]
        pub fn complete_cross_chain_tx(
            origin: OriginFor<T>,
            tx_hash: T::Hash,
        ) -> DispatchResult {
            let _who = ensure_signed(origin)?;

            // Get transaction
            let mut tx = CrossChainTransactions::<T>::get(&tx_hash)
                .ok_or(Error::<T>::TransactionNotFound)?;

            // Update status
            tx.status = TxStatus::Completed;
            CrossChainTransactions::<T>::insert(&tx_hash, &tx);

            // Emit event
            Self::deposit_event(Event::CrossChainTransactionCompleted { tx_hash });

            Ok(())
        }
    }
}

/// Weight functions needed for benchmarking.
pub trait WeightInfo {
    fn link_cosmos_account() -> Weight;
    fn initiate_cross_chain_tx() -> Weight;
    fn complete_cross_chain_tx() -> Weight;
}

impl WeightInfo for () {
    fn link_cosmos_account() -> Weight {
        Weight::from_parts(10_000, 0)
    }
    fn initiate_cross_chain_tx() -> Weight {
        Weight::from_parts(10_000, 0)
    }
    fn complete_cross_chain_tx() -> Weight {
        Weight::from_parts(10_000, 0)
    }
}