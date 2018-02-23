%{
	#include "ParserHelperFunctions.h" 
	#include <stdio.h>
	#include <stdlib.h>
	#include <string.h>

	#if YYBISON
		union YYSTYPE;
		int yylex(union YYSTYPE *, void *);
	#endif

	#define YYDEBUG 1

	typedef void* yyscan_t;
	void yyerror(yyscan_t scanner, struct AtomicComputationList **myStatement, const char *);
%}

// this stores all of the types returned by production rules
%union {
	char *myChar;
	struct AtomicComputationList *myAtomicComputationList;
	struct AtomicComputation *myAtomicComputation;
	struct TupleSpec *myTupleSpec;
	struct AttList *myAttList;
};

%pure-parser
%lex-param {void *scanner}
%parse-param {void *scanner}
%parse-param {struct AtomicComputationList **myPlan}

%token FILTER 
%token APPLY
%token SCAN
%token AGG 
%token JOIN 
%token OUTPUT 
%token GETS
%token HASHLEFT
%token HASHRIGHT
%token HASHONE
%token FLATTEN
%token <myChar> IDENTIFIER
%token <myChar> STRING 

%type <myAtomicComputationList> LogicalQueryPlan
%type <myAtomicComputationList> AtomicComputationList
%type <myAtomicComputation> AtomicComputation
%type <myTupleSpec> TupleSpec
%type <myAttList> AttList

%start LogicalQueryPlan

//******************************************************************************
// SECTION 3
//******************************************************************************
/* This is the PRODUCTION RULES section which defines how to "understand" the 
 * input language and what action to take for each "statment"
 */

%%

LogicalQueryPlan : AtomicComputationList
{
	$$ = $1;
	*myPlan = $$;
}
; 

/*************************************/
/** THIS IS A LIST OF COMPUTATIONS ***/
/*************************************/

AtomicComputationList : AtomicComputationList AtomicComputation
{
	$$ = pushBackAtomicComputation ($1, $2);
}

| AtomicComputation 
{
	$$ =  makeAtomicComputationList ($1);
}
;

/***************************************/
/** THIS IS A PARTICULAR COMPUTATION ***/
/***************************************/

AtomicComputation: TupleSpec GETS APPLY '(' TupleSpec ',' TupleSpec ',' STRING ',' STRING ')'
{
	$$ = makeApply ($1, $5, $7, $9, $11);
}

| TupleSpec GETS AGG '(' TupleSpec ',' STRING ')'
{
	$$ = makeAgg ($1, $5, $7);
}

| TupleSpec GETS SCAN '(' STRING ',' STRING ',' STRING ')'
{
	$$ = makeScan ($1, $5, $7, $9);
}

| TupleSpec GETS OUTPUT '(' TupleSpec ',' STRING ',' STRING ',' STRING ')'
{
	$$ = makeOutput ($1, $5, $7, $9, $11);
}

| TupleSpec GETS JOIN '(' TupleSpec ',' TupleSpec ',' TupleSpec ',' TupleSpec ',' STRING ')'
{
	$$ = makeJoin ($1, $5, $7, $9, $11, $13);
}

| TupleSpec GETS FILTER '(' TupleSpec ',' TupleSpec ',' STRING ')'
{
	$$ = makeFilter ($1, $5, $7, $9);
}

| TupleSpec GETS HASHLEFT '(' TupleSpec ',' TupleSpec ',' STRING ',' STRING ')'
{
	$$ = makeHashLeft ($1, $5, $7, $9, $11);
}

| TupleSpec GETS HASHRIGHT '(' TupleSpec ',' TupleSpec ',' STRING ',' STRING ')'
{
	$$ = makeHashRight ($1, $5, $7, $9, $11);
}

| TupleSpec GETS HASHONE '(' TupleSpec ',' TupleSpec ',' STRING ')'
{
        $$ = makeHashOne ($1, $5, $7, $9);
}

| TupleSpec GETS FLATTEN '(' TupleSpec ',' TupleSpec ',' STRING ')'
{
        $$ = makeFlatten ($1, $5, $7, $9);
}
;

/*********************************************/
/** THIS IS A TUPLE SPEC, LIKE C (a, b, c) ***/
/*********************************************/

TupleSpec : IDENTIFIER '(' AttList ')'
{
	$$ = makeTupleSpec ($1, $3);
}

| IDENTIFIER '(' ')'
{
	$$ = makeEmptyTupleSpec ($1);
}
;

AttList : AttList ',' IDENTIFIER
{
	$$ = pushBackAttribute ($1, $3);
}

| IDENTIFIER
{
	$$ = makeAttList ($1);
}
;


%%

int yylex(YYSTYPE *, void *);

