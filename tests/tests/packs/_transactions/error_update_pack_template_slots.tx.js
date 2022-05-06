export const ERROR_UPDATE_PACK_TEMPLATE_SLOTS = `
    import MFLPackTemplate from "../../../contracts/packs/MFLPackTemplate.cdc"

    /** 
        This tx tries to update a packTemplate slots.
    **/

    pub fun transform(packTemplate: MFLPackTemplate.PackTemplateData ): MFLPackTemplate.PackTemplateData {
        packTemplate.slots[0] = MFLPackTemplate.Slot("fakeType", {"i": "i"}, 424242)
        return packTemplate
    }

    transaction(packTemplateID: UInt64) {

        execute {
            let packTemplate =  MFLPackTemplate.getPackTemplate(id: packTemplateID)
            packTemplate.map(transform)
        }
        
    }
`