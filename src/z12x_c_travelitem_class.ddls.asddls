extend view entity Z12_C_TRAVELITEM with
{
  @Consumption.valueHelpDefinition: [{ entity: { name: '/LRN/437_I_ClassStdVH',
                                                 element: 'ClassID' } }]
  TravelItem.zzclassz12 as zzclassz12
}
