/*
 * Copyright (c) 2002, Oracle and/or its affiliates. All rights reserved.
 */

/*
 * Catalog.xs contains XS code for exacct catalog tag manipulation.  This
 * consists of code to create the @_Constants array and %_Constants hash used
 * for defining constants on the fly via AUTOLOAD, and utility functions for
 * creaing double-typed SVs.
 */

#include "../exacct_common.xh"

/* Pull in the file generated by extract_defines. */
#include "CatalogDefs.xi"

/*
 * This function populates the %_Constants hash and @_Constants array based on
 * the values extracted from the exacct header files by the extract_defines
 * script and written to the .xi file which is included above.  It also creates
 * a const sub for each constant that returns the associcated value.  It should
 * be called from the BOOT section of this module.  The structure of the
 * %_Constants hash is given below - this is used to map between the symbolic
 * and numeric values of the various EX[CTD] constants.  The register() method
 * extends the %_Constants hash with values for the foreign catalog, so that it
 * can be handled in exactly the same way as the built-in catalog.
 *
 * $Constants{catlg}{name}{EXC_DEFAULT} => 0
 *                  ...
 *                  {value}{0} => 'EXC_DEFAULT'
 *                  ...
 *                           *A*
 *           {id}{name}{EXD}{name}{EXD_CREATOR} => 3
 *                          ...
 *                          {value}{3} => 'EXD_CREATOR'
 *                          ...
 *               {value}{0} => *A*
 *               ...
 *           {other}{name}{EXC_CATALOG_MASK} => 251658240
 *                  ...
 *                  {value}{251658240} => 'EXC_CATALOG_MASK'
 *                  ...
 *           {type}{name}{EXT_DOUBLE} => 1342177280
 *                 ...
 *                 {value}{1342177280} => 'EXT_DOUBLE'
 *                 ...
 */
#define	CONST_NAME "::Catalog::_Constants"
static void
define_catalog_constants()
{
	HV		*const_hash, *hv1, *hv2, *hv3;
	AV		*const_ary;
	HV		*type_by_name,  *type_by_value;
	HV		*catlg_by_name, *catlg_by_value;
	HV		*id_by_name,    *id_by_value;
	HV		*other_by_name, *other_by_value;
	constval_t	*cvp;

	/* Create the two new perl variables. */
	const_hash = perl_get_hv(PKGBASE CONST_NAME, TRUE);
	const_ary = perl_get_av(PKGBASE CONST_NAME, TRUE);

	/* Create the 'type' subhash. */
	type_by_name = newHV();
	type_by_value = newHV();
	hv1 = newHV();
	hv_store(const_hash, "type", 4, newRV_noinc((SV*)hv1), 0);
	hv_store(hv1, "name", 4, newRV_noinc((SV*)type_by_name), 0);
	hv_store(hv1, "value", 5, newRV_noinc((SV*)type_by_value), 0);

	/* Create the 'catlg' subhash. */
	catlg_by_name = newHV();
	catlg_by_value = newHV();
	hv1 = newHV();
	hv_store(const_hash, "catlg", 5, newRV_noinc((SV*)hv1), 0);
	hv_store(hv1, "name", 4, newRV_noinc((SV*)catlg_by_name), 0);
	hv_store(hv1, "value", 5, newRV_noinc((SV*)catlg_by_value), 0);

	/*
	 * The 'id' subhash has an extra level of name/value subhashes,
	 * where the upper level is indexed by the catalog prefix (EXD for
	 * the default catalog).  The lower two levels are actually the same
	 * hashes referenced by two parents, and hold the catalog id numeric
	 * values and corresponding string values.
	 */
	id_by_name = newHV();
	id_by_value = newHV();
	hv1 = newHV();
	hv_store(const_hash, "id", 2, newRV_noinc((SV*)hv1), 0);
	hv2 = newHV();
	hv_store(hv1, "name", 4, newRV_noinc((SV*)hv2), 0);
	hv3 = newHV();
	hv_store(hv2, "EXD", 3, newRV_noinc((SV*)hv3), 0);
	hv_store(hv3, "name", 4, newRV_noinc((SV*)id_by_name), 0);
	hv_store(hv3, "value", 5, newRV_noinc((SV*)id_by_value), 0);
	IdValueHash = newHV();
	hv_store(hv1, "value", 5, newRV_noinc((SV*)IdValueHash), 0);
	hv_store_ent(IdValueHash, newSVuv(EXC_DEFAULT), newRV_inc((SV*)hv3), 0);

	/* Create the 'other' subhash, for non-catalog #defines. */
	other_by_name = newHV();
	other_by_value = newHV();
	hv1 = newHV();
	hv_store(const_hash, "other", 5, newRV_noinc((SV*)hv1), 0);
	hv_store(hv1, "name", 4, newRV_noinc((SV*)other_by_name), 0);
	hv_store(hv1, "value", 5, newRV_noinc((SV*)other_by_value), 0);

	/*
	 * Populate %_Constants and %_Constants from the contents of the
	 * generated constants array.
	 */
	for (cvp = constants; cvp->name != NULL; cvp++) {
		HV	*name_hv, *value_hv;
		SV	*name, *value;

		/* Create the name/value SVs, save the name in @_Constants. */
		name = newSVpvn((char *)cvp->name, cvp->len);
		value = newSVuv(cvp->value);
		av_push(const_ary, SvREFCNT_inc(name));

		/*
		 * Decide which hash the name/value belong in,
		 * based on consttype .
		 */
		switch (cvp->consttype) {
		case type:
			name_hv  = type_by_name;
			value_hv = type_by_value;
			break;
		case catlg:
			name_hv = catlg_by_name;
			/* Special case for duplicated-value EXC_NONE tag. */
			if (cvp->value == EXC_NONE &&
			    strcmp(cvp->name, "EXC_NONE") == 0) {
				value_hv = NULL;
			} else {
				value_hv = catlg_by_value;
			}
			break;
		case id:
			name_hv  = id_by_name;
			value_hv = id_by_value;
			break;
		case other:
			name_hv  = other_by_name;
			value_hv = other_by_value;
			break;
		}

		/* Store in the appropriate name & value hashes. */
		if (name_hv) {
			hv_store_ent(name_hv, name, value, 0);
		}
		if (value_hv) {
			hv_store_ent(value_hv, value, name, 0);
		}

		/* Free the name and/or value if they weren't used. */
		if (! name_hv) {
			SvREFCNT_dec(value);
		}
		if (! value_hv) {
			SvREFCNT_dec(name);
		}
	}
}
#undef CONST_NAME

/*
 * The XS code exported to perl is below here.  Note that the XS preprocessor
 * has its own commenting syntax, so all comments from this point on are in
 * that form.
 *
 * All the following are private functions.
 */

MODULE = Sun::Solaris::Exacct::Catalog PACKAGE = Sun::Solaris::Exacct::Catalog
PROTOTYPES: ENABLE

 #
 # Define the stash pointers if required and create and populate @_Constants.
 #
BOOT:
	init_stashes();
	define_catalog_constants();

 #
 # Create and return a double-typed SV.
 #
SV*
_double_type(i, c)
	unsigned int	i;
	char		*c;
CODE:
	RETVAL = newSVuv(i);
	sv_setpv(RETVAL, c);
	SvIOK_on(RETVAL);
OUTPUT:
	RETVAL

 #
 # Return true if the SV contains an IV.
 #
int
_is_iv(sv)
	SV	*sv;
CODE:
	RETVAL = SvIOK(sv);
OUTPUT:
	RETVAL

 #
 # Return true if the SV contains a PV.
 #
int
_is_pv(sv)
	SV	*sv;
CODE:
	RETVAL = SvPOK(sv);
OUTPUT:
	RETVAL

 #
 # Return a blessed reference to a readonly copy of the passed IV
 #
SV*
_new_catalog(sv)
	SV	*sv;
CODE:
	RETVAL = new_catalog(SvUV(sv));
OUTPUT:
	RETVAL

 #
 # Return the integer catalog value from the passed object or SV.
 #
int
_catalog_value(sv)
	SV	*sv;
CODE:
	RETVAL = catalog_value(sv);
OUTPUT:
	RETVAL
