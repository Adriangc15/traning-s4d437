CLASS lhc_handler DEFINITION INHERITING FROM cl_abap_behavior_event_handler.
  PRIVATE SECTION.

    METHODS onTravelCreated FOR ENTITY EVENT
      IMPORTING i_created_travels
                  FOR travel~travelCreated.

ENDCLASS.

CLASS lhc_handler IMPLEMENTATION.

  METHOD ontravelcreated.
    DATA: logs TYPE TABLE FOR CREATE /LRN/437_I_TravelLog.

    logs = CORRESPONDING #( i_created_travels ).

    MODIFY ENTITIES OF /LRN/437_I_TravelLog
        ENTITY TravelLog
        CREATE AUTO FILL CID
        FIELDS ( AgencyID TravelID Origin )
        WITH logs.

  ENDMETHOD.

ENDCLASS.
