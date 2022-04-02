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
            playerAdminClaimCap.borrow<&{MFLPlayer.PlayerAdminClaim}>() ?? panic("Could not borrow PlayerAdminClaim")
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
            packAdminClaimCap.borrow<&{MFLPack.PackAdminClaim}>() ?? panic("Could not borrow PackAdminClaim")
        }
    }
`
const CHECK_PACK_TEMPLATE_ADMIN_CLAIM = `
    import MFLAdmin from "../../../contracts/core/MFLAdmin.cdc"
    import MFLPackTemplate from "../../../contracts/core/MFLPackTemplate.cdc"

    transaction() {
        let packTemplateAdminProxyRef: &MFLAdmin.AdminProxy

        prepare(acct: AuthAccount) {
            self.packTemplateAdminProxyRef = acct.borrow<&MFLAdmin.AdminProxy>(from: MFLAdmin.AdminProxyStoragePath) ?? panic("Could not borrow admin proxy reference")
        }

        execute {
            let packTemplateAdminClaimCap = self.packTemplateAdminProxyRef.getClaimCapability(name: "PackTemplateAdminClaim") ?? panic("PackTemplateAdminClaim capability not found")
            packTemplateAdminClaimCap.borrow<&{MFLPackTemplate.PackTemplateAdminClaim}>() ?? panic("Could not borrow PackTemplateAdminClaim")
        }
    }
`

module.exports = {
    CHECK_PLAYER_ADMIN_CLAIM,
    CHECK_PACK_ADMIN_CLAIM,
    CHECK_PACK_TEMPLATE_ADMIN_CLAIM
}