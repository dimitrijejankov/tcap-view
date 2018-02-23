/* description: Parses and executes mathematical expressions. */

%{

    var parsing_error = function(message) {
        alert(message);
    };

    var pushBackAtomicComputation = function(input, addMe) {
        input.addAtomicComputation(addMe);
        return input;
    };

    var makeAtomicComputationList = function(fromMe) {

        var atomicComputationList = {
            "producers" : {},
            "consumers" : {},
            "scans" : []
        };

        atomicComputationList["addAtomicComputation"] = function (addMe) {

            if (addMe["type"] === "ScanSet") {
                atomicComputationList.scans = atomicComputationList.scans.concat([addMe]);
            }

            atomicComputationList.producers[addMe["output"]["setName"]] = addMe;

            if (!(addMe["input"]["setName"] in atomicComputationList.consumers)) {
                atomicComputationList.consumers[addMe["input"]["setName"]] = [];
            }

            atomicComputationList.consumers[addMe["input"]["setName"]] = atomicComputationList.consumers[addMe["input"]["setName"]].concat([addMe]);

            // now, see if this guy is a join; join is special, because we have to add both inputs to the
            // join to the consumers map
            if (addMe["type"] === "JoinSets") {

                if (!(addMe["rightInput"]["setName"] in atomicComputationList.consumers)) {
                    atomicComputationList.consumers[addMe["rightInput"]["setName"]] = [];
                }

                atomicComputationList.consumers[addMe["rightInput"]["setName"]] = atomicComputationList.consumers[addMe["rightInput"]["setName"]].concat([addMe]);
            }
        };

        // add it
        atomicComputationList.addAtomicComputation(fromMe);

        return atomicComputationList;
    };

    var makeAgg = function(output, input, nodeName) {
        return {
            "input" : input,
            "output" : output,
            "projection" : input,
            "computationName" : nodeName,
            "type" : "HashRight"
        };
    };

    var makeApply = function(output, input, projection, nodeName, opName) {
        return {
            "input" : input,
            "output" : output,
            "projection" : projection,
            "computationName" : nodeName,
            "lambdaName" : opName,
            "type" : "Filter"
        };
    };

    var makeScan = function(output, dbName, setName, nodeName) {
        return {
            "input" : {"setName" : "Empty", "atts" : []},
            "output" : output,
            "projection" : {"setName" : "Empty", "atts" : []},
            "computationName" : nodeName,
            "dbName" : dbName,
            "setName" : setName,
            "type" : "ScanSet"
        };
    };

    var makeOutput = function(output, input, dbName, setName, nodeName) {
        return {
            "input" : input,
            "output" : output,
            "projection" : input,
            "computationName" : nodeName,
            "dbName" : dbName,
            "setName" : setName,
            "type" : "Output"
        };
    };

    var makeJoin = function(output, lInput, lProjection, rInput, rProjection, opName) {
        return {
            "input" : lInput,
            "output" : output,
            "projection" : lProjection,
            "computationName" : opName,
            "rightInput" : rInput,
            "rightProjection" : rProjection,
            "type" : "JoinSets"
        };
    };

    var makeFilter = function(output, input,  projection, nodeName) {
        return {
            "input" : input,
            "output" : output,
            "projection" : projection,
            "computationName" : nodeName,
            "type" : "Filter"
        };
    };

    var makeHashLeft = function(output, input, projection, nodeName, opName) {
        return {
            "input" : input,
            "output" : output,
            "projection" : projection,
            "computationName" : nodeName,
            "lambdaNameIn" : opName,
            "type" : "HashLeft"
        }
    };

    var makeHashRight = function(output, input, projection, nodeName, opName) {
        return {
            "input" : input,
            "output" : output,
            "projection" : projection,
            "computationName" : nodeName,
            "lambdaNameIn" : opName,
            "type" : "HashRight"
        }
    };

    var makeHashOne = function(output, input, projection, nodeName) {
        return {
            "input" : input,
            "output" : output,
            "projection" : projection,
            "computationName" : nodeName,
            "type" : "HashOne"
        };
    };

    var makeFlatten = function(output, input, projection, nodeName) {
        return {
            "input" : input,
            "output" : output,
            "projection" : projection,
            "computationName" : nodeName,
            "type" : "Flatten"
        };
    };

    var makeTupleSpec = function(setName, useMe) {
        return {
            "setName" : setName,
            "atts" : useMe
        };
    };

    var makeEmptyTupleSpec = function(setName) {
        return {
            "setName" : setName,
            "atts" : []
        };
    };

    var pushBackAttribute = function(addToMe, fromMe) {
        return addToMe.concat([fromMe]);
    };

    var makeAttList = function(fromMe) {
        return [fromMe];
    };
%}

/* lexical grammar */
%lex

%s C_COMMENT

%%

"/*"                                                { this.begin("C_COMMENT"); }
<C_COMMENT>"*/"                                     { this.begin("INITIAL"); }
<C_COMMENT>.                                        /* skip comment */
<C_COMMENT>\n                                       /* skip comment */
"<="                                                return 'GETS'
[)]                                                 return 'RPHAR'
[(]                                                 return 'LPHAR'
","                                                 return 'COMMA'
"<="                                                return 'GETS'
[)]                                                 return 'RPHAR'
[(]                                                 return 'LPHAR'
","                                                 return 'COMMA'
[A-Za-z][A-Za-z0-9_-]*                              { yytext = yytext.toUpperCase();

                                                      if(yytext === "FILTER") {
                                                         return 'FILTER';
                                                      }

                                                      if(yytext === "APPLY") {
                                                        return 'APPLY';
                                                      }

                                                      if(yytext === "HASHLEFT") {
                                                         return 'HASHLEFT';
                                                      }

                                                      if(yytext === "HASHRIGHT") {
                                                         return 'HASHRIGHT';
                                                      }

                                                      if(yytext === "HASHONE") {
                                                         return 'HASHONE';
                                                      }

                                                      if(yytext === "FLATTEN") {
                                                         return 'FLATTEN';
                                                      }

                                                      if(yytext === "SCAN") {
                                                         return 'SCAN';
                                                      }

                                                      if(yytext === "AGGREGATE") {
                                                         return 'AGG';
                                                      }

                                                      if(yytext === "JOIN") {
                                                         return 'JOIN';
                                                      }

                                                      if(yytext === "OUTPUT") {
                                                         return 'OUTPUT';
                                                      }

                                                      return 'IDENTIFIER'; }
\"[^\"]*\"|\'[^\']*\'                               { yytext = yytext.toUpperCase().slice(1, -1); return 'STRING'; }
(\s)                                                /* skip */
.                                                   { parsing_error("Unknown token"); }

/lex

%start LogicalQueryPlan

%% /* language grammar */

LogicalQueryPlan
    : AtomicComputationList
        {
            $$ = $1;
            myPlan = $$;
        }
    ;

AtomicComputationList
    : AtomicComputationList AtomicComputation
        {
            $$ = pushBackAtomicComputation ($1, $2);
        }
    | AtomicComputation
        {
            $$ =  makeAtomicComputationList ($1);
        }
    ;

AtomicComputation
    : TupleSpec GETS APPLY LPHAR TupleSpec COMMA TupleSpec COMMA STRING COMMA STRING RPHAR
        {
            $$ = makeApply ($1, $5, $7, $9, $11);
        }
    | TupleSpec GETS AGG LPHAR TupleSpec COMMA STRING RPHAR
        {
            $$ = makeAgg ($1, $5, $7);
        }
    | TupleSpec GETS SCAN LPHAR STRING COMMA STRING COMMA STRING RPHAR
        {
            $$ = makeScan ($1, $5, $7, $9);
        }
    | TupleSpec GETS OUTPUT LPHAR TupleSpec COMMA STRING COMMA STRING COMMA STRING RPHAR
        {
            $$ = makeOutput ($1, $5, $7, $9, $11);
        }
    | TupleSpec GETS JOIN LPHAR TupleSpec COMMA TupleSpec COMMA TupleSpec COMMA TupleSpec COMMA STRING RPHAR
        {
            $$ = makeJoin ($1, $5, $7, $9, $11, $13);
        }
    | TupleSpec GETS FILTER LPHAR TupleSpec COMMA TupleSpec COMMA STRING RPHAR
        {
            $$ = makeFilter ($1, $5, $7, $9);
        }
    | TupleSpec GETS HASHLEFT LPHAR TupleSpec COMMA TupleSpec COMMA STRING COMMA STRING RPHAR
        {
            $$ = makeHashLeft ($1, $5, $7, $9, $11);
        }
    | TupleSpec GETS HASHRIGHT LPHAR TupleSpec COMMA TupleSpec COMMA STRING COMMA STRING RPHAR
        {
            $$ = makeHashRight ($1, $5, $7, $9, $11);
        }
    | TupleSpec GETS HASHONE LPHAR TupleSpec COMMA TupleSpec COMMA STRING RPHAR
        {
            $$ = makeHashOne ($1, $5, $7, $9);
        }
    | TupleSpec GETS FLATTEN LPHAR TupleSpec COMMA TupleSpec COMMA STRING RPHAR
        {
            $$ = makeFlatten ($1, $5, $7, $9);
        }
    ;

TupleSpec
    : IDENTIFIER LPHAR AttList RPHAR
        {
            $$ = makeTupleSpec ($1, $3);
        }
    | IDENTIFIER LPHAR RPHAR
        {
            $$ = makeEmptyTupleSpec ($1);
        }
    ;

AttList
    : AttList COMMA IDENTIFIER
        {
            $$ = pushBackAttribute ($1, $3);
        }
    | IDENTIFIER
        {
            $$ = makeAttList ($1);
        }
    ;
