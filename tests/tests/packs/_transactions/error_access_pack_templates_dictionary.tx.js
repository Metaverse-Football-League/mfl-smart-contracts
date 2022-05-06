export const ERROR_ACCESS_PACK_TEMPLATES_DICTIONARY = `
    import MFLPackTemplate from "../../../contracts/packs/MFLPackTemplate.cdc"

    /** 
        This tx tries to access the packTemplates dictionary directly.
    **/

    transaction(packTemplateId: UInt64) {

        execute {
            let packTemplate <- MFLPackTemplate.packTemplates.remove(key: packTemplateId)
            destroy packTemplate
        }
        
    }
`