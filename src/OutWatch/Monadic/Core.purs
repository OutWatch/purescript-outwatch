module OutWatch.Monadic.Core where

import Prelude
import OutWatch.Attributes as Attr
import Control.Monad.Eff (Eff)
import Control.Monad.RWS.Trans (lift)
import Control.Monad.State (class MonadState, StateT, execStateT, modify)
import DOM (DOM)
import Data.Array (snoc)
import Data.Array.Partial (head)
import OutWatch.Attributes (children)
import OutWatch.Dom.Builder (class AttributeBuilder, class ReceiverBuilder, bindFrom, setTo)
import OutWatch.Dom.EmitterBuilder (class EmitterBuilder, emitFrom)
import OutWatch.Dom.Types (VDom)
import OutWatch.Sink (Handler, SinkLike, createHandlerEff)
import Partial.Unsafe (unsafePartial)
import RxJS.Observable (Observable)

---- Core -----------------------------------------------------------------

type HTML e a = StateT (Array (VDom e)) (Eff (dom::DOM|e)) a

push :: forall vdom m. (MonadState (Array vdom) m) => vdom -> m Unit
push = (\e l -> snoc l e) >>> modify

unsafeFirst :: forall a. Array a -> a 
unsafeFirst a = unsafePartial (head a)

build :: forall e a. HTML e a -> Eff (dom::DOM|e) (Array (VDom e))
build b = execStateT b []

-- Handlers, Observables, Sinks --------------------------------------------

createHandler_ :: forall a e. Array a -> HTML e (Handler e a)
createHandler_ a = lift $ (createHandlerEff a)

-- Elements ----------------------------------------------------------------

wrapTag :: forall e. (Array (VDom e) -> (VDom e)) -> HTML e Unit -> HTML e Unit
wrapTag e b = lift (e <$> execStateT b []) >>= push 

wrapTag_ :: forall attributes m e. (MonadState (Array (VDom e)) m) =>
   attributes -> (attributes -> VDom e) -> m Unit
wrapTag_ val tag =  push (tag val)

-- Attributes --------------------------------------------------------------

wrapAttribute :: forall builder value e. AttributeBuilder builder value =>  
    builder -> value -> HTML e Unit
wrapAttribute b v = push (setTo b v)
-- infix 5 setTo as :=

-- type_ :: forall e. String -> HTML e Unit
-- type_ = wrapAttribute Attr.tpe

-- valueShow_ :: forall s e. Show s => s -> HTML e Unit
-- valueShow_ = wrapAttribute Attr.valueShow

-- max_ :: forall e. Number -> HTML e Unit
-- max_ = wrapAttribute Attr.max

-- Emitter -----------------------------------------------------------------

wrapEmitter :: forall builder a e r. EmitterBuilder builder a e => 
  builder -> SinkLike e a r -> HTML e Unit
wrapEmitter b s = push (emitFrom b s)
-- infix 5 emitFrom as ==>

inputNumber_ :: forall e r. SinkLike e Number r -> HTML e Unit
inputNumber_ = wrapEmitter Attr.inputNumber

-- Receiver ----------------------------------------------------------------

wrapReceiver :: forall builder stream e. ReceiverBuilder builder stream e => 
  builder -> stream -> HTML e Unit
wrapReceiver b s = push (bindFrom b s)
-- infix 5 bindFrom as <==

children_ :: forall e. Observable (Array (VDom e)) -> HTML e Unit
children_ s = push (bindFrom children s)

-- -- instance childReceiverBuilder :: ReceiverBuilder ChildStreamReceiverBuilder (Observable (VDom e)) e  where
-- --   bindFrom builder obs =
-- --     let valueStream = map modifierToVNode obs
-- --     in Receiver (ChildStreamReceiver valueStream)

-- -- children_2 :: forall e. Observable (HTML e Unit) -> HTML e Unit
-- -- children_2 = do 
-- --     children

-- childShow_ :: forall a e. Show a => Observable a -> HTML e Unit
-- childShow_ = wrapReceiver childShow
-- -- ReceiverBuilder builder stream eff | stream -> eff, builder -> stream where
-- --   bindFrom :: builder -> stream -> VDom eff

