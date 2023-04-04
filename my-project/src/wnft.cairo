from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin
from starkware.cairo.common.uint256 import Uint256
from starkware.cairo.common.math import assert_not_zero
from starkware.starknet.common.syscalls import get_caller_address, get_contract_address

from openzeppelin.token.erc721.library import ERC721

from openzeppelin.token.erc721.enumerable.library import ERC721Enumerable, ERC721_Enumerable_AutoId

from openzeppelin.access.ownable.library import Ownable

from openzeppelin.introspection.erc165.library import ERC165

@contract
namespace my_contract {
    struct TokenMetadata {
        string name
        string symbol
        string image_url
    }

    @storage_var
    felt[] public all_tokens

    @storage_var
    mapping(felt:felt) public token_metadata

    @storage_var
    mapping(felt:felt) public token_owners

    @storage_var
    mapping(felt:felt[]) public owned_tokens

    @event
    deposit(dst: address, wad: felt)

    @event
    withdrawal(src: address, wad: felt)

    @external
    func deposit() -> (){
        wad: felt = msg.value;
        self._mint(msg.sender, wad);
        self.emit(Deposit(msg.sender, wad));
    }

    @external
    func withdraw(amount: felt) -> (){
        bal: felt = self.balances[msg.sender];
        require(bal >= amount, "Insufficient funds.");
        self.burn(msg.sender, amount);
        msg.sender.transfer(amount);
        self.emit(Withdrawal(msg.sender, amount));
    }

    @external
    @implements(ERC721)
    @payable
    func mint(nft_id: felt, metadata: TokenMetadata) {
        require(token_owners[nft_id] == 0, "Token already exists");
        token_owners[nft_id] = msg.sender;
        token_metadata[nft_id] = metadata;

        all_tokens.push(nft_id);

        owned_tokens[msg.sender].push(nft_id);

        emit Transfer(ZERO_ADDRESS, msg.sender, nft_id);
    }

    @external
    @view
    @implements(ERC721)
    func owner_of(token_id: felt) -> () {
        require(token_owners[token_id] != 0, "Token does not exist");
        return token_owners[token_id];
    }

    @external
    @view
    @implements(ERC721)
    func get_metadata(token_id: felt) -> (TokenMetadata: felt) {
        require(token_metadata[token_id].name != "", "Token does not exist");
        return token_metadata[token_id];
    }

    @external
    @payable
    @implements(ERC721)
    func transfer(to: address, token_id: felt) {
        _transfer(msg.sender, to, token_id);
    }

    @external
    @implements(ERC721)
    @payable
    func transfer_from(from: address, to: address, token_id: felt) {
        require(is_approved_or_owner(from, token_id), "Not approved or owner");
        _transfer(from, to, token_id);
    }

    @external
    @implements(ERC721)
    @payable
    func exchange(to: address, token_id: felt, from: address, token_id_2: felt) {
        require(is_approved_or_owner(from, token_id_2), "Not approved or owner");
        require(is_approved_or_owner(to, token_id), "Not approved or owner");

        _transfer(from, to, token_id_2);
        _transfer(to, from, token_id);
    }

    @external
    @implements(ERC721Enumerable)
    @view
    func total_supply() -> (){
        return all_tokens.length;
    }

    @external
    @implements(ERC721Enumerable)
    @view
    func token_by_index(index: felt) -> (){
        require(index < all_tokens.length, "Index out of bounds");
        return all_tokens[index];
    }

    @external
    @implements(ERC721Enumerable)
    @view
    func token_of_owner_by_index(owner: address, index: felt) -> (tokenId:felt){
        require(index < owned_tokens[owner].length, "Index out of bounds");
        return owned_tokens[owner][index];
    }  

    @external
    func is_approved_or_owner(sender: address, token_id: felt) -> (address: felt) {
        let owner := token_owners[token_id];
        return (sender == owner) or (allowance[owner][sender] == token_id);
    }
}



