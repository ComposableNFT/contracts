import { testERC721C } from "./testERC721C";
import { testERC721CMutexComponents } from "./testERC721CMutexComponents";
import { testERC721CCompatibleContracts } from "./testERC721CCompatibleContracts";
import { testERC721CUniqueComponents } from "./testERC721CUniqueComponents";
import { testERC721CUniqueCompatible } from "./testERC721CUniqueCompatible";

testERC721C();
testERC721CUniqueComponents();
testERC721CCompatibleContracts();
testERC721CUniqueCompatible();
testERC721CMutexComponents();