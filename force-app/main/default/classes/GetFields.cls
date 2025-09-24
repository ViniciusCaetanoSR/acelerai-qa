public class GetFields {
    public List<String> getFields(String objectName, String layoutName) {
            //pegar o layout do objeto
            String layoutFullName = String.format('{0}-{1}', new String[]{objectName, layoutName});
            List<Metadata.Metadata> layouts = Metadata.Operations.retrieve(Metadata.MetadataType.Layout, new List<String> {layoutFullName});
    
            //pegar os campos do layout
            List<String> fields = new List<String>();
            Metadata.Layout layoutMd = (Metadata.Layout)layouts.get(0);
            for (Metadata.LayoutSection section : layoutMd.layoutSections) {
                for (Metadata.LayoutColumn column : section.layoutColumns) {
                    if (column.layoutItems != null) {
                        for (Metadata.LayoutItem item : column.layoutItems) {
                            fields.add(item.field);
                        }
                    }
                }
            }
            return fields;
	}
}