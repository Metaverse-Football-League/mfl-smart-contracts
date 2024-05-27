const CHECK_PLAYER_ADMIN_CLAIM = `
    import MFLAdmin from "../../../contracts/core/MFLAdmin.cdc"
    import MFLPlayer from "../../../contracts/players/MFLPlayer.cdc"

    transaction() {
        let adminProxyRef: auth(MFLAdmin.AdminProxyAction) &MFLAdmin.AdminProxy

        prepare(acct: auth(BorrowValue) &Account) {
            self.adminProxyRef = acct.storage.borrow<auth(MFLAdmin.AdminProxyAction) &MFLAdmin.AdminProxy>(from: MFLAdmin.AdminProxyStoragePath) ?? panic("Could not borrow admin proxy reference")
        }
        
        execute {
            let playerAdminClaimCap = self.adminProxyRef.getClaimCapability(name: "PlayerAdminClaim") ?? panic("PlayerAdminClaim capability not found")
            playerAdminClaimCap.borrow<auth(MFLPlayer.PlayerAdminAction) &MFLPlayer.PlayerAdmin>() ?? panic("Could not borrow PlayerAdminClaim")
        }
    }
`;

const CHECK_PACK_ADMIN_CLAIM = `
    import MFLAdmin from "../../../contracts/core/MFLAdmin.cdc"
    import MFLPack from "../../../contracts/packs/MFLPack.cdc"

    transaction() {
        let adminProxyRef: auth(MFLAdmin.AdminProxyAction) &MFLAdmin.AdminProxy

        prepare(acct: auth(BorrowValue) &Account) {
            self.adminProxyRef = acct.storage.borrow<auth(MFLAdmin.AdminProxyAction) &MFLAdmin.AdminProxy>(from: MFLAdmin.AdminProxyStoragePath) ?? panic("Could not borrow admin proxy reference")
        }
        
        execute {
            let packAdminClaimCap = self.adminProxyRef.getClaimCapability(name: "PackAdminClaim") ?? panic("PackAdminClaim capability not found")
            packAdminClaimCap.borrow<auth(MFLPack.PackAdminAction) &MFLPack.PackAdmin>() ?? panic("Could not borrow PackAdminClaim")
        }
    }
`;

const CHECK_PACK_TEMPLATE_ADMIN_CLAIM = `
    import MFLAdmin from "../../../contracts/core/MFLAdmin.cdc"
    import MFLPackTemplate from "../../../contracts/packs/MFLPackTemplate.cdc"

    transaction() {
        let adminProxyRef: auth(MFLAdmin.AdminProxyAction) &MFLAdmin.AdminProxy

        prepare(acct: auth(BorrowValue) &Account) {
            self.adminProxyRef = acct.storage.borrow<auth(MFLAdmin.AdminProxyAction) &MFLAdmin.AdminProxy>(from: MFLAdmin.AdminProxyStoragePath) ?? panic("Could not borrow admin proxy reference")
        }
        
        execute {
            let packTemplateAdminClaimCap = self.adminProxyRef.getClaimCapability(name: "PackTemplateAdminClaim") ?? panic("PackTemplateAdminClaim capability not found")
            packTemplateAdminClaimCap.borrow<auth(MFLPackTemplate.PackTemplateAdminAction) &MFLPackTemplate.PackTemplateAdmin>() ?? panic("Could not borrow PackTemplateAdminClaim")
        }
    }
`;

const CHECK_CLUB_ADMIN_CLAIM = `
    import MFLAdmin from "../../../contracts/core/MFLAdmin.cdc"
    import MFLClub from "../../../contracts/clubs/MFLClub.cdc"

    transaction() {
        let adminProxyRef: auth(MFLAdmin.AdminProxyAction) &MFLAdmin.AdminProxy

        prepare(acct: auth(BorrowValue) &Account) {
            self.adminProxyRef = acct.storage.borrow<auth(MFLAdmin.AdminProxyAction) &MFLAdmin.AdminProxy>(from: MFLAdmin.AdminProxyStoragePath) ?? panic("Could not borrow admin proxy reference")
        }
        
        execute {
            let clubAdminClaimCap = self.adminProxyRef.getClaimCapability(name: "ClubAdminClaim") ?? panic("ClubAdminClaim capability not found")
            clubAdminClaimCap.borrow<auth(MFLClub.ClubAdminAction) &MFLClub.ClubAdmin>() ?? panic("Could not borrow ClubAdminClaim")
        }
    }
`;

const CHECK_SQUAD_ADMIN_CLAIM = `
    import MFLAdmin from "../../../contracts/core/MFLAdmin.cdc"
    import MFLClub from "../../../contracts/clubs/MFLClub.cdc"

    transaction() {
        let adminProxyRef: auth(MFLAdmin.AdminProxyAction) &MFLAdmin.AdminProxy

        prepare(acct: auth(BorrowValue) &Account) {
            self.adminProxyRef = acct.storage.borrow<auth(MFLAdmin.AdminProxyAction) &MFLAdmin.AdminProxy>(from: MFLAdmin.AdminProxyStoragePath) ?? panic("Could not borrow admin proxy reference")
        }
        
        execute {
            let squadAdminClaimCap = self.adminProxyRef.getClaimCapability(name: "SquadAdminClaim") ?? panic("SquadAdminClaim capability not found")
            squadAdminClaimCap.borrow<auth(MFLClub.SquadAdminAction) &MFLClub.SquadAdmin>() ?? panic("Could not borrow SquadAdminClaim")
        }
    }
`;

module.exports = {
  CHECK_PLAYER_ADMIN_CLAIM,
  CHECK_PACK_ADMIN_CLAIM,
  CHECK_PACK_TEMPLATE_ADMIN_CLAIM,
  CHECK_CLUB_ADMIN_CLAIM,
  CHECK_SQUAD_ADMIN_CLAIM,
};
