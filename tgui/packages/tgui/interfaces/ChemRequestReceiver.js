import { useBackend, useLocalState, useSharedState } from '../backend';
import { Button, LabeledList, Input, Section, Flex, Box, Stack, Tabs } from '../components';
import { Window } from '../layouts';

import { capitalize } from '../../common/string';

const ChemRequest = (props, context) => {
  const { act } = useBackend(context);
  const {
    name,
    id,
    reagent_name,
    reagent_color,
    volume,
    notes,
    area,
    state,
    interactable,
  } = props;
  // some mild colour hackery to make the text visible on (hopefully) any reagent colour
  const color_string = "rgba(" + reagent_color[0] + "," + reagent_color[1] + ", " + reagent_color[2] + ", 1)";
  const lightness = reagent_color.reduce((a, b) => a + b, 0)/3;
  return (
    <Section height>
      <Flex direction="column" height={9}>
        <Flex.Item grow={1}>
          <Stack vertical>
            <Stack.Item>{name} requested</Stack.Item>
            <Stack.Item align="center"><Box width={16} textAlign="center" backgroundColor={color_string} color={lightness > 255/2 ? "black" : "white"}>{capitalize(reagent_name)} ({volume}u)</Box></Stack.Item>
            <Stack.Item style={{ 'overflow-wrap': 'break-word' }}>from {area} <br /> {notes && `Notes: ${notes}`}</Stack.Item>
          </Stack>
        </Flex.Item>
        <Flex.Item>
          <Box>
            {state === "pending" && (
              <>
                <Button disabled={!interactable} align="center" width="49.5%" color="red" icon="ban" onClick={() => { act("deny", { id: id }); }}>Deny</Button>
                <Button disabled={!interactable} align="center" width="49.5%" icon="check" onClick={() => { act("fulfil", { id: id }); }}>Mark as fulfilled</Button>
              </>
            )}
            {state !== "pending" && (
              <Box align="center" backgroundColor={state === "denied" ? "red" : "green"}>{capitalize(state)}</Box>
            )}
          </Box>
        </Flex.Item>
      </Flex>
    </Section>
  );
};

export const ChemRequestReceiver = (props, context) => {
  const { act, data } = useBackend(context);
  const [tabIndex, setTabIndex] = useLocalState(context, 'tabIndex', 1);
  const {
    requests,
    allowed,
  } = data;
  let request_index = 0;
  return (
    <Window title="Chemical requests" width={600} height={600}>
      <Window.Content>
        <Tabs>
          <Tabs.Tab
            selected={tabIndex === 1}
            onClick={() => setTabIndex(1)}>
            Pending
          </Tabs.Tab>
          <Tabs.Tab
            selected={tabIndex === 2}
            onClick={() => setTabIndex(2)}>
            History
          </Tabs.Tab>
        </Tabs>
        <Stack wrap="wrap">
          {requests.map((request) => {
            if ((request.state === "pending" && tabIndex === 1) || (request.state !== "pending" && tabIndex === 2)) {
              return (
                <Stack.Item py={1} width={24} key={request.id} ml={request_index++ === 0 ? 1 : undefined}>
                  <ChemRequest interactable={allowed} {...request} />
                </Stack.Item>
              );
            }
          })}
        </Stack>
      </Window.Content>
    </Window>
  );
};
