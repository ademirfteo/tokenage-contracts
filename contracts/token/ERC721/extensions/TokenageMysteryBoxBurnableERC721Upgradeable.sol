// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import 'hardhat/console.sol';
import '@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol';
import "@openzeppelin/contracts/utils/Strings.sol";

import './ITokenageMysteryBoxBurnable.sol';
import '../../../DefaultPausableUpgradeable.sol';

abstract contract TokenageMysteryBoxBurnableERC721Upgradeable is
    DefaultPausableUpgradeable,
    ERC721EnumerableUpgradeable,
    ITokenageMysteryBoxBurnable
{
    using Strings for uint16;

    bytes32 public constant BURNER_ROLE = keccak256('BURNER_ROLE');

    mapping(uint256 => uint16) public tokenIdToType;
    mapping(uint256 => uint256) public tokenIdToUserSeed;

    // solhint-disable-next-line func-name-mixedcase, private-vars-leading-underscore
    function __TokenageMysteryBoxBurnableERC721_init(
        address adminAddress,
        address burnerAddress,
        string memory name,
        string memory symbol
    ) public onlyInitializing {
        __ERC721_init(name, symbol);
        __DefaultPausable_init(adminAddress);
        _grantRole(BURNER_ROLE, burnerAddress);
    }

    function getType(uint256 tokenId) external view override returns (uint16) {
        require(_exists(tokenId), 'Token not exists');
        return tokenIdToType[tokenId];
    }

    function burn(uint256 tokenId) external override onlyRole(BURNER_ROLE) {
        _burn(tokenId);
    }

    function setUserSeed(uint256[] calldata tokenIds, uint256 userSeed) external whenNotPaused nonReentrant {
        require(tokenIds.length > 0, 'TokenIds empty');
        require(userSeed > 0, 'userSeed zero');
        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            require(ownerOf(tokenId) == msg.sender, 'Not owner');
            require(tokenIdToUserSeed[tokenId] == 0, 'Seed already set');
        }
        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            tokenIdToUserSeed[tokenId] = userSeed;
            emit MysteryBoxUserSeedSet(msg.sender, tokenId, userSeed);
        }
    }

    function getUserSeed(uint256 tokenId) external view override returns (uint256) {
        return tokenIdToUserSeed[tokenId];
    }

    function isOwnerOfTokensAndUserSeedSet(address owner, uint256[] calldata tokenIds) external view returns (bool) {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            if (ownerOf(tokenId) != owner) {
                return false;
            }
            if (tokenIdToUserSeed[tokenId] == 0) {
                return false;
            }
        }
        return true;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), 'ERC721Metadata: URI query for nonexistent token');

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenIdToType[tokenId].toString())) : '';
    }

    function _setType(uint256 tokenId, uint16 ticketType) internal virtual {
        require(tokenIdToType[tokenId] == 0, 'Type already set');
        tokenIdToType[tokenId] = ticketType;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override whenNotPaused {
        // validate only on transfer, burning is still allowed for BURNER_ROLE only
        if (to != address(0)) {
            require(tokenIdToUserSeed[tokenId] == 0, 'Transfer forbidden');
        }
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721EnumerableUpgradeable, AccessControlUpgradeable) returns (bool) {
        return interfaceId == type(ITokenageMysteryBoxBurnable).interfaceId || super.supportsInterface(interfaceId);
    }
}
