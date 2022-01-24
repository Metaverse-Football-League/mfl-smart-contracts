
const PLAYER_ADMIN_CLAIM = `
    import MFLAdmin from "../../../contracts/core/MFLAdmin.cdc"
    import MFLPlayer from "../../../contracts/players/MFLPlayer.cdc"

    transaction() {
        let playerAdminProxyRef: &MFLAdmin.AdminProxy

        prepare(acct: AuthAccount) {
            self.playerAdminProxyRef = acct.borrow<&MFLAdmin.AdminProxy>(from: MFLAdmin.AdminProxyStoragePath) ?? panic("Could not borrow admin proxy reference")
        }
        
        execute {
            let playerAdminClaimCap = self.playerAdminProxyRef.getClaimCapability(name: "PlayerAdminClaim") ?? panic("PlayerAdminClaim capability not found")
            let playerAdminClaimRef = playerAdminClaimCap.borrow<&{MFLPlayer.PlayerAdminClaim}>() ?? panic("Could not borrow PlayerAdminClaim")
        }
    }
`

const DROP_ADMIN_CLAIM = `
    import MFLAdmin from "../../../contracts/core/MFLAdmin.cdc"
    import MFLDrop from "../../../contracts/drops/MFLDrop.cdc"

    transaction() {
        let dropAdminProxyRef: &MFLAdmin.AdminProxy

        prepare(acct: AuthAccount) {
            self.dropAdminProxyRef = acct.borrow<&MFLAdmin.AdminProxy>(from: MFLAdmin.AdminProxyStoragePath) ?? panic("Could not borrow admin proxy reference")
        }

        execute {
            let dropAdminClaimCap = self.dropAdminProxyRef.getClaimCapability(name: "DropAdminClaim") ?? panic("DropAdminClaim capability not found")
            let dropAdminClaimRef = dropAdminClaimCap.borrow<&{MFLDrop.DropAdminClaim}>() ?? panic("Could not borrow DropAdminClaim")
        }
    }
`
const PACK_TEMPLATE_ADMIN_CLAIM = `
    import MFLAdmin from "../../../contracts/core/MFLAdmin.cdc"
    import MFLPackTemplate from "../../../contracts/core/MFLPackTemplate.cdc"

    transaction() {
        let packTemplateAdminProxyRef: &MFLAdmin.AdminProxy

        prepare(acct: AuthAccount) {
            self.packTemplateAdminProxyRef = acct.borrow<&MFLAdmin.AdminProxy>(from: MFLAdmin.AdminProxyStoragePath) ?? panic("Could not borrow admin proxy reference")
        }

        execute {
            let packTemplateAdminClaimCap = self.packTemplateAdminProxyRef.getClaimCapability(name: "PackTemplateAdminClaim") ?? panic("PackTemplateAdminClaim capability not found")
            let packTemplateAdminClaimRef = packTemplateAdminClaimCap.borrow<&{MFLPackTemplate.PackTemplateAdminClaim}>() ?? panic("Could not borrow PackTemplateAdminClaim")
        }
    }
`

module.exports = {
    PLAYER_ADMIN_CLAIM,
    DROP_ADMIN_CLAIM,
    PACK_TEMPLATE_ADMIN_CLAIM
}