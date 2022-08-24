const CHECK_PLAYER_ADMIN_CLAIM = `
    import MFLAdmin from "../../../contracts/core/MFLAdmin.cdc"
    import MFLPlayer from "../../../contracts/players/MFLPlayer.cdc"

    transaction() {
        let playerAdminProxyRef: &MFLAdmin.AdminProxy

        prepare(acct: AuthAccount) {
            self.playerAdminProxyRef = acct.borrow<&MFLAdmin.AdminProxy>(from: MFLAdmin.AdminProxyStoragePath) ?? panic("Could not borrow admin proxy reference")
        }
        
        execute {
            let playerAdminClaimCap = self.playerAdminProxyRef.getClaimCapability(name: "PlayerAdminClaim") ?? panic("PlayerAdminClaim capability not found")
            playerAdminClaimCap.borrow<&MFLPlayer.PlayerAdmin{MFLPlayer.PlayerAdminClaim}>() ?? panic("Could not borrow PlayerAdminClaim")
        }
    }
`

const CHECK_PACK_ADMIN_CLAIM = `
    import MFLAdmin from "../../../contracts/core/MFLAdmin.cdc"
    import MFLPack from "../../../contracts/packs/MFLPack.cdc"

    transaction() {
        let packAdminProxyRef: &MFLAdmin.AdminProxy

        prepare(acct: AuthAccount) {
            self.packAdminProxyRef = acct.borrow<&MFLAdmin.AdminProxy>(from: MFLAdmin.AdminProxyStoragePath) ?? panic("Could not borrow admin proxy reference")
        }

        execute {
            let packAdminClaimCap = self.packAdminProxyRef.getClaimCapability(name: "PackAdminClaim") ?? panic("PackAdminClaim capability not found")
            packAdminClaimCap.borrow<&MFLPack.PackAdmin{MFLPack.PackAdminClaim}>() ?? panic("Could not borrow PackAdminClaim")
        }
    }
`
const CHECK_PACK_TEMPLATE_ADMIN_CLAIM = `
    import MFLAdmin from "../../../contracts/core/MFLAdmin.cdc"
    import MFLPackTemplate from "../../../contracts/packs/MFLPackTemplate.cdc"

    transaction() {
        let packTemplateAdminProxyRef: &MFLAdmin.AdminProxy

        prepare(acct: AuthAccount) {
            self.packTemplateAdminProxyRef = acct.borrow<&MFLAdmin.AdminProxy>(from: MFLAdmin.AdminProxyStoragePath) ?? panic("Could not borrow admin proxy reference")
        }

        execute {
            let packTemplateAdminClaimCap = self.packTemplateAdminProxyRef.getClaimCapability(name: "PackTemplateAdminClaim") ?? panic("PackTemplateAdminClaim capability not found")
            packTemplateAdminClaimCap.borrow<&MFLPackTemplate.PackTemplateAdmin{MFLPackTemplate.PackTemplateAdminClaim}>() ?? panic("Could not borrow PackTemplateAdminClaim")
        }
    }
`

const CHECK_CLUB_ADMIN_CLAIM = `
    import MFLAdmin from "../../../contracts/core/MFLAdmin.cdc"
    import MFLClub from "../../../contracts/clubs/MFLClub.cdc"

    transaction() {
        let clubAdminProxyRef: &MFLAdmin.AdminProxy

        prepare(acct: AuthAccount) {
            self.clubAdminProxyRef = acct.borrow<&MFLAdmin.AdminProxy>(from: MFLAdmin.AdminProxyStoragePath) ?? panic("Could not borrow admin proxy reference")
        }

        execute {
            let clubAdminClaimCap = self.clubAdminProxyRef.getClaimCapability(name: "ClubAdminClaim") ?? panic("ClubAdminClaim capability not found")
            clubAdminClaimCap.borrow<&MFLClub.ClubAdmin{MFLClub.ClubAdminClaim}>() ?? panic("Could not borrow ClubAdminClaim")
        }
    }
`

const CHECK_SQUAD_ADMIN_CLAIM = `
    import MFLAdmin from "../../../contracts/core/MFLAdmin.cdc"
    import MFLClub from "../../../contracts/clubs/MFLClub.cdc"

    transaction() {
        let squadAdminProxyRef: &MFLAdmin.AdminProxy

        prepare(acct: AuthAccount) {
            self.squadAdminProxyRef = acct.borrow<&MFLAdmin.AdminProxy>(from: MFLAdmin.AdminProxyStoragePath) ?? panic("Could not borrow admin proxy reference")
        }

        execute {
            let squadAdminClaimCap = self.squadAdminProxyRef.getClaimCapability(name: "SquadAdminClaim") ?? panic("SquadAdminClaim capability not found")
            squadAdminClaimCap.borrow<&MFLClub.SquadAdmin{MFLClub.SquadAdminClaim}>() ?? panic("Could not borrow SquadAdminClaim")
        }
    }
`

module.exports = {
    CHECK_PLAYER_ADMIN_CLAIM,
    CHECK_PACK_ADMIN_CLAIM,
    CHECK_PACK_TEMPLATE_ADMIN_CLAIM,
    CHECK_CLUB_ADMIN_CLAIM,
    CHECK_SQUAD_ADMIN_CLAIM
}