@AbapCatalog.extensibility: { extensible: true,
                              allowNewDatasources: false,
                              dataSources: [ 'TravelItem' ],
                              elementSuffix: 'Z12' }
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Extension Travel Item'
@Metadata.ignorePropagatedAnnotations: true
@ObjectModel.usageType:{
    serviceQuality: #X,
    sizeCategory: #S,
    dataClass: #MIXED
}
define view entity Z12_E_TRAVELITEM
  as select from z12_tritem as TravelItem
{
  key item_uuid as ItemUuid
}
