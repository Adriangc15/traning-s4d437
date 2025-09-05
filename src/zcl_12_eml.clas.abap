CLASS zcl_12_eml DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    INTERFACES if_oo_adt_classrun .

    CONSTANTS c_agency_id TYPE /dmo/agency_id VALUE '070050'.
    CONSTANTS c_travel_id TYPE /dmo/travel_id VALUE '00004212'.

  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS zcl_12_eml IMPLEMENTATION.


  METHOD if_oo_adt_classrun~main.

    READ ENTITIES OF z12_r_travel
        ENTITY Travel ALL FIELDS
        WITH VALUE #( ( AgencyId = c_agency_id TravelId = c_travel_id ) )
        RESULT DATA(travels)
        FAILED DATA(failed).

    IF failed IS NOT INITIAL.
      out->write( |Travel { c_travel_id } does not exist.| ).
    ELSE.
      DATA(travel) = travels[ 1 ].
      MODIFY ENTITIES OF z12_r_travel
          ENTITY Travel
          UPDATE FIELDS ( Description )
          WITH VALUE #( ( %key        = travel-%key
                          Description = 'This is a new description 3' ) )
          FAILED failed.
      IF failed IS INITIAL.
        COMMIT ENTITIES.
        out->write( 'Description updated.' ).
      ELSE.
        ROLLBACK ENTITIES.
        out->write( 'Update failed.' ).
      ENDIF.
    ENDIF.
  ENDMETHOD.
ENDCLASS.
